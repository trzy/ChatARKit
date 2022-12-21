#
# message_handling.py
# Bart Trzynadlowski
#
# Message and connection session handling class for use with TCP sessions.
# Inherit from this class and create handler methods using the @handler
# decorator. For example:
#
#   class ServerHandler(MessageHandler):
#     async def on_connect(self, session: Session):
#       print("Connection from: %s" % session.remote_endpoint)
#       await session.send(HelloMessage(message = "Hello from %s" % os.path.basename(__file__)))
#
#     async def on_disconnect(self, session: Session):
#       print("Disconnected from: %s" % session.remote_endpoint)
#
#     @handler(HelloMessage)
#     async def handle_HelloMessage(self, session: Session, msg: HelloMessage, timestamp: float):
#       print("Hello received: %s" % msg.message)
#

#
# TODO:
#   - _register_message_handlers() is unable to check that the message name in
#     handle_MessageName is actually spelled the same as in the @handler()
#     decorator.
#

from dataclasses import dataclass
import functools
import inspect
import json
import sys

from networking.serialization import LaserTagJSONDecoder


def handler(message_type):
    def handler_decorator(func):
        @functools.wraps(func)
        async def handler_wrapper(self, session, dictionary, timestamp):
            try:
                # Decode message and pass to actual wrapped handler
                msg = LaserTagJSONDecoder().decode(message_type = message_type, dictionary = dictionary)
                await func(self, session, msg, timestamp)
            except:
                print("Error: Failed to handle message %s: %s" % (str(message_type), sys.exc_info()))
        return handler_wrapper
    return handler_decorator


class MessageHandler:
    def __init__(self):
        self._message_handlers = {}
        self._register_message_handlers()

    async def on_connect(self, session):
        pass

    async def on_disconnect(self, session):
        pass

    async def handle_message(self, session, json_string, timestamp):
        dictionary = json.loads(json_string)
        if "__id" in dictionary:
            id = dictionary["__id"]
            if id in self._message_handlers:
                await self._message_handlers[id](session = session, dictionary = dictionary, timestamp = timestamp)
            else:
                print("Error: No handler registered for message: %s" % id)
        else:
            print("Error: Invalid message encountered")

    def _get_decorators(self, function):
        """
        Returns a list of decorator names.
        Parameters
        ----------
        function : Callable
            Decorated method or function.
        Returns
        -------
        List[str]
            List of decorators as strings.
            Example:
                Given:
                @my_decorator
                @another_decorator
                def some_function():
                    pass
                >>>get_decorators(some_function)
                ['@my_decorator', '@another_decorator']
        """
        source = inspect.getsource(function)
        index = source.find("def ")
        decorators = []
        for line in source[:index].strip().splitlines():
            if line.strip()[0] == "@":
                # Eliminate white space in the middle
                parts = line.strip().split()
                if len(parts[0]) > 1:   # no space between @ and decorator name
                    decorator = parts[0]
                else:                   # whitespace between @ and decorator name
                    decorator = "".join(parts[0:2])
                # If decorator has arguments, cut off at first parenthesis
                paren_idx = decorator.find("(")
                if paren_idx > 0:
                    decorator = decorator[0:paren_idx]
                decorators.append(decorator)
        return decorators

    def _register_message_handlers(self):
        for name, method in inspect.getmembers(self, predicate = inspect.ismethod):
            if "@handler" in self._get_decorators(method):
                parts = name.split("_")
                if len(parts) >= 2 and parts[0] == "handle":
                    message_id = "_".join(parts[1:])
                    #TODO: check that handler takes arg for json string
                    self._message_handlers[message_id] = method
                    print("Registered handler for message: %s" % message_id)
                else:
                    print("Error: Failed to register method %s as message handler because it is named incorrectly" % name)