//
//  PBLite.swift
//  Hangover
//
//  Created by Peter Sobot on 5/24/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation
import JavaScriptCore

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

typealias OptionalField = AnyObject?

func unwrapOptionalType(any: Any) -> Any.Type? {
    //  This is super nasty, but works. (Doesn't work in Playground, because of lldb name mangling.)
    //  Also doesn't work for nested classes. Boo.

    let dynamicTypeName = "\(Mirror(reflecting: any).subjectType)"
    let containedTypeName = dynamicTypeName.stringByReplacingOccurrencesOfString("Swift.Optional<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "")
    return NSClassFromString(containedTypeName)
}

func unwrapOptionalArrayType(any: Any) -> Any.Type? {
    // blehhhh
    // don't look at me
    // I'm hideous

    let dynamicTypeName = "\(Mirror(reflecting: any).subjectType)"
    if dynamicTypeName.contains("Swift.Optional<Swift.Array") {
        let containedTypeName = dynamicTypeName.stringByReplacingOccurrencesOfString("Swift.Optional<", withString: "").stringByReplacingOccurrencesOfString("Swift.Array<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "")
        return NSClassFromString(containedTypeName)
    } else {
        return nil
    }
}

func unwrapArray(any:Any) -> Any? {
    let mi:Mirror = Mirror(reflecting: any)
    if mi.displayStyle != Mirror.DisplayStyle.Collection {
        return any
    }
    if mi.children.count == 0 { return nil } // Optional.None
    let (_, some) = mi.children.first!
    return some
}

func getArrayMessageType(arr: Any) -> Message.Type? {
    //  hackety hack, this is extremely brittle but Swift's introspection isn't perfect yet
    if arr is [CONVERSATION_ID] { return CONVERSATION_ID.self }
    if arr is [USER_ID] { return USER_ID.self }
    if arr is [CLIENT_EVENT] { return CLIENT_EVENT.self }
    if arr is [CLIENT_ENTITY] { return CLIENT_ENTITY.self }
    if arr is [MESSAGE_SEGMENT] { return MESSAGE_SEGMENT.self }
    if arr is [MESSAGE_ATTACHMENT] { return MESSAGE_ATTACHMENT.self }
    if arr is [CLIENT_CONVERSATION_PARTICIPANT_DATA] { return CLIENT_CONVERSATION_PARTICIPANT_DATA.self }
    if arr is [CLIENT_CONVERSATION_READ_STATE] { return CLIENT_CONVERSATION_READ_STATE.self }
    if arr is [ENTITY_GROUP_ENTITY] { return ENTITY_GROUP_ENTITY.self }

    // ... etc, one for each different kind of array we might have.
    // This is horrible, but if we can find a function that'll take
    // an Any (really a [Something]) and return Something,
    // this function doesn't need to exist anymore.
    return nil
}

func getArrayEnumType(arr: Any) -> Enum.Type? {
    if arr is [ClientConversationView] { return ClientConversationView.self }
    return nil
}

func valueWithTypeCoercion(
    property: Any,
    value: AnyObject?
) -> AnyObject? {
    //  Hacky, but if we're doing this at runtime, we don't get Swift's nice implicit Convertables.
    if property is NSDate || unwrapOptionalType(property) is NSDate.Type {
        if let number = value as? NSNumber {
            let timestampAsDate = from_timestamp(number)
            return timestampAsDate
        }
    }
    return value
}

class Message : NSObject {
    required override init() { }
    class func isOptional() -> Bool { return false }

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

//  Due to peculiarities in Swift's type system, we need to pass in
//  "type" here.
func parse<T: Message>(type: T.Type, input: NSArray?) -> T? {
    if let arr = input {
        let instance = type.init()
        let reflection = Mirror(reflecting: instance)
        let children = Array(reflection.children)
        for var i = 0; i < min(arr.count, children.count); i++ {
            let propertyName = children[i].label!
            let property = children[i].value

            //  Unwrapping an optional sub-struct
            if let type = unwrapOptionalType(property) as? Message.Type {
                let val: (AnyObject?) = parse(type, input: arr[i] as? NSArray)
                instance.setValue(val, forKey: propertyName)

            //  Using a non-optional sub-struct
            } else if let message = property as? Message {
                let val: (AnyObject?) = parse(message.dynamicType, input: arr[i] as? NSArray)
                instance.setValue(val, forKey: propertyName)

            //  Unwrapping an optional enum
            } else if let type = unwrapOptionalType(property) as? Enum.Type {
                let val: (AnyObject?) = type.init(value: (arr[i] as! NSNumber))
                instance.setValue(val, forKey: propertyName)

            //  Using a non-optional sub-struct
            } else if let enumv = property as? Enum {
                let val: (AnyObject?) = enumv.dynamicType.init(value: (arr[i] as! NSNumber))
                instance.setValue(val, forKey: propertyName)
            } else {
                if arr[i] is NSNull {
                    instance.setValue(nil, forKey: propertyName)
                } else {
                    if let elementType = unwrapOptionalArrayType(property) {
                        let elementMessageType = elementType as! T.Type
                        let val = (arr[i] as! NSArray).map { parse(elementMessageType, input: $0 as? NSArray)! }
                        instance.setValue(val, forKey:propertyName)
                    } else if let elementType = getArrayMessageType(property) {
                        let val = (arr[i] as! NSArray).map { parse(elementType, input: $0 as? NSArray)! }
                        instance.setValue(val, forKey:propertyName)
                    } else if let elementType = getArrayEnumType(property) {
                        let val = (arr[i] as! NSArray).map { elementType.init(value: ($0 as! NSNumber)) }
                        instance.setValue(val, forKey:propertyName)
                    } else {
                        instance.setValue(valueWithTypeCoercion(property, value: arr[i]), forKey:propertyName)
                    }
                }
            }
        }
        return instance
    } else {
        //  Raise error: expecting array
        return nil
    }
}

func parseProtoJSON<T: Message>(input: NSData) -> T? {
    if let parsedObject = JSContext().evaluateScript(
        "a = " + (NSString(data: input, encoding: 4)! as String)
    ).toArray() {
        return parse(T.self, input: parsedObject)
    }
    return nil
}

func parseJSON<T: Message>(input: NSData) -> T? {
    if let parsedObject = JSContext().evaluateScript(
        "a = " + (NSString(data: input, encoding: 4)! as String)
        ).toDictionary() {
            return parseDictionary(T.self, obj: parsedObject)
    }
    return nil
}

func parseDictionary<T: Message>(type: T.Type, obj: NSDictionary) -> T? {
    let instance = type.init()
    let reflection = Mirror(reflecting: instance)
    for child in reflection.children {
        let propertyName = child.label!
        let property = child.value

        let value: AnyObject? = obj[propertyName]

        //  Unwrapping an optional sub-struct
        if let type = unwrapOptionalType(property) as? Message.Type {
            let val: (AnyObject?) = parseDictionary(type, obj: value as! NSDictionary)
            instance.setValue(val, forKey: propertyName)

            //  Using a non-optional sub-struct
        } else if let message = property as? Message {
            let val: (AnyObject?) = parseDictionary(message.dynamicType, obj: value as! NSDictionary)
            instance.setValue(val, forKey: propertyName)

            //  Unwrapping an optional enum
        } else if let type = unwrapOptionalType(property) as? Enum.Type {
            let val: (AnyObject?) = type.init(value: (value as! NSNumber))
            instance.setValue(val, forKey: propertyName)

            //  Using a non-optional sub-struct
        } else if let enumv = property as? Enum {
            let val: (AnyObject?) = enumv.dynamicType.init(value: (value as! NSNumber))
            instance.setValue(val, forKey: propertyName)
        } else {
            if value is NSNull || value == nil {
                instance.setValue(nil, forKey: propertyName)
            } else {
                if let elementType = getArrayMessageType(property) {
                    let val = (value as! NSArray).map { parseDictionary(elementType, obj: $0 as! NSDictionary)! }
                    instance.setValue(val, forKey:propertyName)
                } else if let elementType = getArrayEnumType(property) {
                    let val = (value as! NSArray).map { elementType.init(value: ($0 as! NSNumber)) }
                    instance.setValue(val, forKey:propertyName)
                } else {
                    instance.setValue(valueWithTypeCoercion(property, value: value), forKey: propertyName)
                }
            }
        }
    }
    return instance
}