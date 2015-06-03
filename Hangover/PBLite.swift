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

    func parse(input: AnyObject?) -> AnyObject? {
        return input
    }

    func serialize(input: AnyObject?) -> AnyObject? {
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

class RepeatedField {
    // A field which may be repeated any number of times.
    let field: Field
    let is_optional: Bool

    init(field: Field, is_optional: Bool = false) {
        self.field = field
        self.is_optional = is_optional
    }

    func parse(input: AnyObject?, serialize: Bool = false) -> AnyObject? {
        if input == nil && !is_optional {
            //  raise error? not an optional field
            return nil
        } else if input == nil && is_optional {
            return nil
        }

        if let arr = input as? NSArray {
            return map(arr) { (field_input: AnyObject?) in
                if serialize {
                    return self.field.serialize(field_input)!
                } else {
                    return self.field.parse(field_input)!
                }
            }
        } else {
            //  Raise error: expecting array
            return nil
        }
    }

    func serialize(input: AnyObject?) -> AnyObject? {
        return self.parse(input, serialize: true)
    }
}

typealias OptionalField = AnyObject?

func unwrap(any:Any) -> Any? {
    let mi:MirrorType = reflect(any)
    if mi.disposition != .Optional {
        return any
    }
    if mi.count == 0 { return nil } // Optional.None
    let (name,some) = mi[0]
    return some.valueType
}

class Message : NSObject {
    required override init() { }
    class func isOptional() -> Bool { return false }

    func parse(input: NSArray?) -> Self? { return self.dynamicType.parse(input) }
    class func parse(input: NSArray?) -> Self? {
        if input == nil && !isOptional() {
            //  raise error? not an optional field
            return nil
        } else if input == nil && isOptional() {
            return nil
        }

        if let arr = input {
            var instance = self()
            let reflection = reflect(instance)
            for var i = 0; i < min(arr.count, reflection.count - 1); i++ {
                let propertyName = reflection[i + 1].0
                let property = reflection[i + 1].1.value

                //  Unwrapping an optional sub-struct
                if let type = unwrap(property) as? Message.Type {
                    let val: (AnyObject?) = type.parse(arr[i] as? NSArray)
                    instance.setValue(val, forKey: propertyName)

                //  Using a non-optional sub-struct
                } else if let message = property as? Message {
                    let val: (AnyObject?) = message.parse(arr[i] as? NSArray)
                    instance.setValue(val, forKey: propertyName)
                } else {
                    if arr[i] is NSNull {
                        instance.setValue(nil, forKey: propertyName)
                    } else {
                        instance.setValue(arr[i], forKey: propertyName)
                    }
                }
            }
            return instance
        } else {
            //  Raise error: expecting array
            return nil
        }
    }

    func serialize(input: AnyObject?) -> AnyObject? {
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
        return nil
    }
}