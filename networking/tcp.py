#
# tcp.py
# Bart Trzynadlowski
#
# Asynchronous TCP server and client. Designed to be run as asynchronous tasks
# in an event loop.
#

import asyncio
import sys
import time
import uuid

from networking.message_handling import MessageHandler
from networking.serialization import LaserTagJSONEncoder


class Session:
  def __init__(self, reader, writer, remote_endpoint, message_handler):
    self.remote_endpoint = remote_endpoint
    self._reader = reader
    self._writer = writer
    self._message_handler = message_handler

  def __del__(self):
    print("Session object destroyed")

  def __str__(self):
    return str(self.remote_endpoint)

  async def send(self, obj):
    """
    Sends an object as a JSON-encoded message using our custom framing
    protocol:

      Offset  Length  Description
      ------  ------  -----------
      0       4       Length of entire framed message, as a little-endian 32-
                      bit unsigned integer, including these 4 bytes: N.
      4       1       The ASCII character 'J'.
      5       N - 5   Payload as encoded by LaserTagJSONEncoder. The length is
                      the length given at offset 0 less 5 bytes (i.e., the JSON
                      payload itself).

    Parameters
    ----------
    obj : object
      A dataclass object that will automatically be serialized before
      transmission.
    """
    try:
      json_string = LaserTagJSONEncoder().encode(obj)
      json_bytes = json_string.encode("utf-8")
      total_size = 4 + 1 + len(json_bytes)  # size prefix + 'J' + JSON payload
      message_bytes = (
          int(total_size).to_bytes(length = 4, byteorder = "little")
          + b"J"
          + json_bytes
      )
      self._writer.write(message_bytes)
      #print("Sent %d bytes" % len(message_bytes))
      await self._writer.drain()
    except Exception as e:
      # Connection error, most likely. Nothing we can do but swallow it and
      # hope it will be detected elsewhere. Makes for a more ergonomic API when
      # we don't have to worry about send() blowing up.
      print("Exception caught while trying to send: %s" % e)
      pass

  async def _run(self):
    while True:
      # Read header and payload
      try:
        size_prefix = await self._reader.readexactly(4)
        timestamp = time.time()
        total_size = int.from_bytes(bytes = size_prefix, byteorder = "little")
        payload_size = total_size - 4
        if payload_size > 0:
          payload = await self._reader.readexactly(payload_size)
          if total_size > 5:
            # A JSON payload exists
            json_string = payload[1:].decode("utf-8")
            #print("Received %d bytes" % total_size)
            try:
              await self._message_handler.handle_message(session = self, json_string = json_string, timestamp = timestamp)
            except Exception as e:
              print("Terminating session due to exception from message handler: %s" % e)
              break
      except ConnectionError as e:
        print("Disconnected from %s: %s" % (self.remote_endpoint, e))
        break
      except Exception as e:
        print("Unexpected error in Session: %s" % e)
        break
    # Helps ensure the connection on the other end sees a disconnect,
    # particularly in cases where the message handler raised an exception above
    await self._close()

  async def _close(self):
    try:
      self._writer.close()
      await self._writer.wait_closed()
    except Exception as e:
      # If the socket was actually disconnected already, ConnectionError occurs
      pass

class Server:
  def __init__(self, port: int, message_handler: MessageHandler):
    self.id = str(uuid.uuid1())
    self._port = port
    self.sessions = []
    self._message_handler = message_handler

  async def _on_client_connect(self, reader, writer):
    # Construct a client object
    socket = writer.get_extra_info("socket")
    if socket == None:
      remote_endpoint = "unknown endpoint"
    else:
      peername = socket.getpeername()
      remote_endpoint = ("%s:%d" % peername[0:2]) if len(peername) >= 2 else None
      remote_endpoint = (remote_endpoint if remote_endpoint is not None else "unknown endpoint")
    print("New connection from %s" % remote_endpoint)
    session = Session(reader = reader, writer = writer, remote_endpoint = remote_endpoint, message_handler = self._message_handler)
    try:
      await self._message_handler.on_connect(session = session)
      self.sessions.append(session)
      await session._run()
      print("Ended session with %s" % remote_endpoint)
      await self._message_handler.on_disconnect(session = session)
    except Exception as e:
      print("Unexpected error from Session or its message handler: %s" % e)
    finally:
      await session._close()
      self.sessions.remove(session)

  async def run(self):
    try:
      server = await asyncio.start_server(client_connected_cb = self._on_client_connect, host = None, port = self._port)
    except Exception as e:
      print("Error: %s" % e)
    async with server:
      print("Starting server on port %d..." % self._port)
      await server.serve_forever()


class Client:
  def __init__(self, connect_to: str, message_handler: MessageHandler):
    self.id = str(uuid.uuid1())
    self._host, self._port = self._parse_endpoint(endpoint = connect_to)
    self._session = None
    self._message_handler = message_handler

  async def run(self):
    print("Connecting to %s:%s..." % (self._host, self._port))
    reader, writer = await asyncio.open_connection(host = self._host, port = self._port)
    self._session = Session(reader = reader, writer = writer, remote_endpoint = self._host + ":" + str(self._port), message_handler = self._message_handler)
    try:
      await self._message_handler.on_connect(session = self._session)
      await self._session._run()
      return await self._message_handler.on_disconnect(session = self._session)
    except Exception as e:
      print("Unexpected error from Session or its message handler: %s" % e)
    finally:
      await self._session._close()

  async def stop(self):
    await self._session._close()

  @staticmethod
  def _parse_endpoint(endpoint: str) -> (str, int):
    components = endpoint.split(":")
    if len(components) != 2:
      raise ValueError("Endpoint is missing port. Expected format is: hostname:port")
    hostname = components[0]
    try:
      port = int(components[1])
    except ValueError as ve:
      raise ValueError("Endpoint port is not an integer")
    if port >= 65535 or port < 0:
      raise ValueError("Endpoint port must be in range [0,65535]")
    return hostname, port

