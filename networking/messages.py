#
# messages.py
# Bart Trzynadlowski
#
# Definition of messages for communication between server and clients.
#

from dataclasses import dataclass
from typing import List


@dataclass
class HelloMessage:
  message: str

@dataclass
class ChatGPTPromptMessage:
  prompt: str

@dataclass
class ChatGPTResponseMessage:
  prose: str
  code: str