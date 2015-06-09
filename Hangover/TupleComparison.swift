//
//  TupleComparison.swift
//  Hangover
//
//  Created by Peter Sobot on 6/8/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

func == <A:Equatable, B:Equatable> (tuple1:(A,B),tuple2:(A,B)) -> Bool
{
    return (tuple1.0 == tuple2.0) && (tuple1.1 == tuple2.1)
}

func == <A:Equatable, B:Equatable, C:Equatable, D:Equatable> (tuple1:(A,B,C,D),tuple2:(A,B,C,D)) -> Bool
{
    return (tuple1.0 == tuple2.0) && (tuple1.1 == tuple2.1) && (tuple1.2 == tuple2.2) && (tuple1.3 == tuple2.3)
}