#
# serialization.py
# Bart Trzynadlowski
#
# Custom serialization of dataclasses into JSON-encoded messages, with custom
# framing that encodes the message type as a string. A corresponding
# serializer/deserializer exists on the C# side.
#

import dataclasses
import json
import numpy as np


class LaserTagJSONEncoder(json.JSONEncoder):
    """
    Serializes to JSON according to the format expected of LaserTag apps.
    Converts NumPy tensors, when possible, to Unity-formatted equivalents
    and converts dataclasses to the expected message schema by inserting
    an "__id" field that corresponds to the object's class name.
    """

    def default(self, obj):
        if type(obj) == np.ndarray:
            if obj.shape == (4, 4):
                # Convert to Unity-format 4x4 matrix payload
                return {
                    "e00": obj[0, 0],
                    "e01": obj[0, 1],
                    "e02": obj[0, 2],
                    "e03": obj[0, 3],
                    "e10": obj[1, 0],
                    "e11": obj[1, 1],
                    "e12": obj[1, 2],
                    "e13": obj[1, 3],
                    "e20": obj[2, 0],
                    "e21": obj[2, 1],
                    "e22": obj[2, 2],
                    "e23": obj[2, 3],
                    "e30": obj[3, 0],
                    "e31": obj[3, 1],
                    "e32": obj[3, 2],
                    "e33": obj[3, 3],
                }
            elif obj.shape == (3,):
                # Convert to Unity-format Vector3 payload
                return {
                    "x": obj[0],
                    "y": obj[1],
                    "z": obj[2]
                }
        elif type(obj) == np.int32:
            return int(obj)
        elif type(obj) == np.float32:
            return float(obj)
        elif dataclasses.is_dataclass(obj):
            obj_dict = dataclasses.asdict(obj)
            obj_dict["__id"] = type(obj).__name__
            return obj_dict
        return super().default(obj)


class LaserTagJSONDecoder:
    def decode(self, message_type, json_string):
        """
        Deserializes JSON as a specified dataclass type. Capable of handling nested
        dataclasses. Operates by first decoding JSON to a Python dictionary using the
        standard library decoder. Then, converts each dictionary value to the type
        specified by the dataclass using a recursive decoder function. If required
        keys are missing or there is no way to convert between value types, throws.
        """
        if not dataclasses.is_dataclass(message_type):
            raise TypeError("Cannot deserialize JSON string because message type '%s' is not a dataclass" % message_type.__name__)

        # Decode as dictionary
        json_object = json.loads(json_string)

        return self._decode(element_type = message_type, element_value = json_object)

    def decode(self, message_type, dictionary):
        """
        Deserializes JSON as a specified dataclass. Identical to the form that
        takes a string but instead takes a Python dictionary.
        """
        if not dataclasses.is_dataclass(message_type):
            raise TypeError("Cannot deserialize JSON string because message type '%s' is not a dataclass" % message_type.__name__)

        return self._decode(element_type = message_type, element_value = dictionary)

    def _decode(self, element_type, element_value):
        if dataclasses.is_dataclass(element_type) and type(element_value) == dict:
            # Convert dict -> dataclass

            # Remove fields from dictionary that are unknown to the message
            # type
            fields = dataclasses.fields(element_type)
            field_names = { field.name for field in fields }
            dictionary = { key: value for key, value in element_value.items() if key in field_names }

            # Iterate all fields in dataclass and convert the corresponding
            # entries in the decoded JSON dictionary as needed
            for field in dataclasses.fields(element_type):
                if field.name in dictionary:
                    decoded_value = dictionary[field.name]
                    if type(decoded_value) != field.type:
                        dictionary[field.name] = self._decode(element_type = field.type, element_value = decoded_value)
                else:
                    raise TypeError("Cannot deserialize JSON string because field '%s' is missing from encoded object of type '%s'" % (field.name, element_type.__name__))

            # Convert to dataclass
            return element_type(**dictionary)
        elif element_type == np.ndarray and type(element_value) == dict:
            # Convert dict -> numpy.ndarray
            keys = element_value.keys()
            if len(keys) == 16:
                required_keys = { "e00", "e01", "e02", "e03", "e10", "e11", "e12", "e13", "e20", "e21", "e22", "e23", "e30", "e31", "e32", "e33" }
                if element_value.keys() != required_keys:
                    raise TypeError("Cannot deserialize JSON string because encoded NumPy array is not a 4x4 matrix")
                return np.array([
                    [ element_value["e00"], element_value["e01"], element_value["e02"], element_value["e03"] ],
                    [ element_value["e10"], element_value["e11"], element_value["e12"], element_value["e13"] ],
                    [ element_value["e20"], element_value["e21"], element_value["e22"], element_value["e23"] ],
                    [ element_value["e30"], element_value["e31"], element_value["e32"], element_value["e33"] ]
                ])
            elif len(keys) == 3:
                required_keys = { "x", "y", "z" }
                if element_value.keys() != required_keys:
                    raise TypeError("Cannot deserialize JSON string because encoded NumPy array is not a 3-vector")
                return np.array([ element_value["x"], element_value["y"], element_value["z"] ])
            else:
                raise TypeError("Cannot deserialize JSON string because encoded NumPy array length %d is unsupported" % len(element_value))
        else:
            raise TypeError("Cannot deserialize JSON string because no decoder for '%s' from '%s' is implemented" % (element_type.__name__, type(element_value).__name__))