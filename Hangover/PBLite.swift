//
//  PBLite.swift
//  Hangover
//
//  Created by Peter Sobot on 5/24/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

//A parser for the pblite serialization format.
//
//pblite (sometimes called "protojson") is a way of encoding Protocol Buffer
//messages to arrays. Google uses this in Hangouts because JavaScript handles
//arrays better than bytes.
//
//This module allows parsing lists together with a schema to produce
//programmer-friendly objects. The conversation from not-quite-json strings to
//lists can be done using hangups.javascript.
//
//See:
//https://code.google.com/p/google-protorpc/source/browse/python/protorpc/
//protojson.py
//
//TODO: Serialization code is currently unused and doesn't have any tests.

class Field {
    // An untyped field, corresponding to a primitive type.
    let is_optional: Bool
    init(is_optional: Bool = false) {
        self.is_optional = is_optional
    }

    func parse(input: String?) -> String? {
        return input
    }

    func serialize(input: String?) -> String? {
        return self.parse(input)
    }
}

protocol GoogleEnum {
    static func fromRawValue(Int) -> GoogleEnum
    static func fromRawValue(String) -> GoogleEnum
    func toRawValue() -> Int
}

class EnumField<_enum: GoogleEnum> {
    // An untyped field, corresponding to a primitive type.
    func parse(input: String) -> GoogleEnum? {
        return _enum.fromRawValue(input)
    }

    func serialize(input: String?) -> String? {
        return self.parse(input!)?.toRawValue().description
    }
}

//class RepeatedField(object):
//
//    """A field which may be repeated any number of times.
//
//    Corresponds to a list.
//    """
//
//    def __init__(self, field, is_optional=False):
//        self._field = field
//        self._is_optional = is_optional
//
//    def parse(self, input_, serialize=False):
//        """Parse the message.
//
//        Raises ValueError if the input is None and the RepeatedField is not
//        optional, or if the input is not a list.
//        """
//        # Validate input:
//        if input_ is None and not self._is_optional:
//            raise ValueError('RepeatedField is not optional')
//        elif input_ is None and self._is_optional:
//            return None
//        elif not isinstance(input_, list):
//            raise ValueError('RepeatedField expected list but got {}'
//                             .format(type(input_)))
//
//        res = []
//        for field_input in input_:
//            try:
//                if serialize:
//                    res.append(self._field.serialize(field_input))
//                else:
//                    res.append(self._field.parse(field_input))
//            except ValueError as e:
//                raise ValueError('RepeatedField item: {}'.format(e))
//        return res
//
//    def serialize(self, input_):
//        """Serialize the message.
//
//        Raises ValueError if the input is None and the RepeatedField is not
//        optional, or if the input is not a list.
//        """
//        return self.parse(input_, serialize=True)
//
//
//class Message(object):
//
//    """A field consisting of a collection of fields paired with a name.
//
//    Corresponds to an object (SimpleNamespace).
//
//    The input may be shorter than the number of fields and the trailing fields
//    will be assigned None. The input may be longer than the number of fields
//    and the trailing input items will be ignored. Fields with name None will
//    cause the corresponding input item to be optional and ignored.
//
//    """
//
//    def __init__(self, *args, is_optional=False):
//        self._name_field_pairs = args
//        self._is_optional = is_optional
//
//    def parse(self, input_):
//        """Parse the message.
//
//        Raises ValueError if the input is None and the Message is not optional,
//        or if any of the contained Fields fail to parse.
//        """
//        # Validate input:
//        if input_ is None and not self._is_optional:
//            raise ValueError('Message is not optional')
//        elif input_ is None and self._is_optional:
//            return None
//        elif not isinstance(input_, list):
//            raise ValueError('Message expected list but got {}'
//                             .format(type(input_)))
//
//        # Pad input with Nones if necessary
//        input_ = itertools.chain(input_, itertools.repeat(None))
//        res = types.SimpleNamespace()
//        for (name, field), field_input in zip(self._name_field_pairs, input_):
//            if name is not None:
//                try:
//                    p = field.parse(field_input)
//                except ValueError as e:
//                    raise ValueError('Message field \'{}\': {}'.
//                                     format(name, e))
//                setattr(res, name, p)
//        return res
//
//    def serialize(self, input_):
//        """Serialize the message.
//
//        Raises ValueError if the input is None and the Message is not optional,
//        or if any of the contained Fields fail to parse.
//        """
//        # Validate input:
//        if input_ is None and not self._is_optional:
//            raise ValueError('Message is not optional')
//        elif input_ is None and self._is_optional:
//            return None
//        elif not isinstance(input_, types.SimpleNamespace):
//            raise ValueError(
//                'Message expected types.SimpleNamespace but got {}'
//                .format(type(input_))
//            )
//
//        res = []
//        for name, field in self._name_field_pairs:
//            if name is not None:
//                field_input = getattr(input_, name)
//                res.append(field.serialize(field_input))
//            else:
//                res.append(None)
//        return res