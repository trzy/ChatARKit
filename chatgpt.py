#
# chatgpt.py
# Bart Trzynadlowski
#
# ChatGPT relay server. Relays prompts received via a TCP socket to ChatGPT and
# returns the results.
#

import argparse
import asyncio
import os
import sys
import time
import weakref

from pyChatGPT import ChatGPT

from networking.tcp import Server
from networking.tcp import Session
from networking.message_handling import handler
from networking.message_handling import MessageHandler
from networking.messages import *


#
# ChatGPT Task
#
# Receives prompts via a queue and queries ChatGPT.
#

class ChatGPTTask:
  def __init__(self, prompt_queue: asyncio.Queue, num_prompts: int):
    self._prompt_queue = prompt_queue
    self._num_prompts = num_prompts if num_prompts > 0 else None  # if num_prompts <= 0, accept unlimited prompts
    self._session_token = input("Enter session token >>>")
    self._chat_gpt = ChatGPT(self._session_token)

  async def run(self):
    # Process prompts
    self._chat_gpt.reset_conversation()
    while (self._num_prompts is None) or self._num_prompts > 0:
      # Process prompt and await response
      prompt, callback = await self._prompt_queue.get()
      response = self._send_prompt(prompt = prompt)

      # Parse response
      prose, code = self._parse_response(response = response)

      # Print response
      print("Response (Prose):")
      print("-----------------")
      print(prose)
      print("")
      print("Response (Code):")
      print("----------------")
      print(code)

      # Callback (async)
      if callback is not None:
        await callback(prose, code)

      # Finish this job
      self._prompt_queue.task_done()
      if self._num_prompts is not None:
        self._num_prompts -= 1

  def _send_prompt(self, prompt):
    return self._chat_gpt.send_message(prompt)
    #time.sleep(20)  # simulate a long delay
    #return {"message": "``` /* Insert test code here */ ```"}

  def _parse_response(self, response):
    if not "message" in response:
      return "", ""

    prose = []
    code = []

    # Separate into alternating prose and code segments
    segments = response["message"].split("```")

    # Separate code from prose
    for i in range(len(segments)):
      if (i & 1) == 0:
        prose.append(segments[i])
      else:
        code.append(segments[i].strip())  # remove whitespace at the beginning and end of code segments

    # Strip code of junk
    prefix = "Copy code`"
    postfix = "`"
    for i in range(len(code)):
      if code[i].startswith(prefix):
        code[i] = code[i][len(prefix):]
      if code[i].endswith(postfix):
        code[i] = code[i][0:-len(postfix)]
      code[i] = code[i].replace("\\", "")

    # Return single strings
    return "".join(prose), "".join(code)


#
# Server Task
#
# Receives prompts via JSON messages.
#

class ServerTask(MessageHandler):
  def __init__(self, port: int, prompt_queue: asyncio.Queue):
    super().__init__()
    self._server = Server(port = port, message_handler = self)
    self._sessions = set()
    self._prompt_queue = prompt_queue

  async def run(self):
    await self._server.run()

  async def on_connect(self, session: Session):
    print("Connection from: %s" % session.remote_endpoint)
    await session.send(HelloMessage(message = "Hello from %s" % os.path.basename(__file__)))
    self._sessions.add(session)

  async def on_disconnect(self, session: Session):
    print("Disconnected from: %s" % session.remote_endpoint)
    self._sessions.remove(session)

  @handler(HelloMessage)
  async def handle_HelloMessage(self, session: Session, msg: HelloMessage, timestamp: float):
    print("Hello received: %s" % msg.message)

  @handler(ChatGPTPromptMessage)
  async def handle_ChatGPTPromptMessage(self, session: Session, msg: ChatGPTPromptMessage, timestamp: float):
    print("Received prompt from: %s" % session)
    session_ref = weakref.ref(session)
    async def send_response(prose, code):
      s = session_ref()
      if s is not None:
        await s.send(ChatGPTResponseMessage(prose = prose, code = code))
    self._prompt_queue.put_nowait((msg.prompt, send_response))


#
# Interactive Prompt Task
#
# Takes prompts from stdin.
#

class InteractivePromptTask:
  def __init__(self, prompt_queue: asyncio.Queue):
    self._prompt_queue = prompt_queue

  async def run(self):
    while True:
      print("Enter prompt:")
      prompt = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
      self._prompt_queue.put_nowait((prompt, None))


#
# Main Program
#

if __name__ == "__main__":
  parser = argparse.ArgumentParser("chatgpt")
  parser.add_argument("--port", metavar = "port", type = int, action = "store", default = 6502, help = "Run server on specified port")
  parser.add_argument("--prompt", metavar = "text", type = str, action = "store", help = "Run single prompt and exit")
  parser.add_argument("--interactive", action = "store_true", help = "Interactive prompt")
  options = parser.parse_args()
  queue = asyncio.Queue()
  loop = asyncio.new_event_loop()
  tasks = []
  chat_gpt = ChatGPTTask(prompt_queue = queue, num_prompts = 1 if options.prompt else 0)
  tasks.append(loop.create_task(chat_gpt.run()))
  if options.prompt:
    queue.put_nowait((options.prompt, None))
  else:
    if options.interactive:
      interactive_prompt = InteractivePromptTask(prompt_queue = queue)
      tasks.append(loop.create_task(interactive_prompt.run()))
    server = ServerTask(port = options.port, prompt_queue = queue)
    tasks.append(loop.create_task(server.run()))
  loop.run_until_complete(asyncio.gather(*tasks))