//: Playground - noun: a place where people can play

import UIKit

protocol TestableClass: class{
    func ifOverride<T:Any>(functionName: String,funcCall: @escaping ()->T?) -> T?
}
extension TestableClass{
    func ifOverrideFunction(functionName: String,funcCall: ()->())->Any?{
        let returnVal : (Bool,Any?) = MockHelper.functionIsGettingCalled(functionName: functionName)
        if !returnVal.0{
            funcCall()
        }
        return returnVal.1
    }
    func ifOverride<T:Any>(functionName: String = #function,funcCall: @escaping ()->T?) -> T?{
        var parentReturnValue:T?
        if let overrideReturnVal = (ifOverrideFunction(functionName: functionName) { () -> () in
            parentReturnValue = funcCall()
            }) as? T {
                return overrideReturnVal
        }
        return parentReturnValue
    }
}

class mainClass{
    func testFunction(){
        anotherFunctionWithMultipleParameter(param1: "a",param2: "b",param3: "c")
    }
    func thisAwesomeFunctionWithParameter(funcName:String = #function){
        testFunction()
    }
    func anotherFunctionWithMultipleParameter(param1:String,param2:String,param3:String){
        print("\(param1) : \(param2) : \(param3)")
    }
    func functionWithReturnType() -> String{
        return "functionWithReturnType"
    }
}

class testClass: mainClass, TestableClass{
    override func testFunction(){
        ifOverride{
            super.testFunction()
        }
    }
    override func thisAwesomeFunctionWithParameter(funcName:String = #function){
        ifOverride{
            super.thisAwesomeFunctionWithParameter()
        }
    }
    override func functionWithReturnType() -> String{
        return ifOverride { () -> String? in
            return super.functionWithReturnType()
        }!
    }
    override func anotherFunctionWithMultipleParameter(param1:String,param2:String,param3:String){
        ifOverride{
            super.anotherFunctionWithMultipleParameter(param1: param1, param2: param2, param3: param3)
        }
    }
}

public class MockActionable {
    var actions = [MockAction]()
    init(_ funcBlock: (()->Any?)?){
        if let funcBlock = funcBlock{
            addAction(action: MockAction(theClosure: funcBlock))
        }
    }
    public func andDo(closure: @escaping () -> Void) -> MockActionable {
        let action = MockAction(theClosure: { () -> () in
            closure()
        })
        addAction(action: action)
        return self
    }
    
    public func andReturn<T>(value: T) -> MockActionable {
        return andReturnValue(closure: { () -> T in
            return value
        })
    }
    
    private func andReturnValue(closure: @escaping () -> Any) -> MockActionable {
        let action = MockAction(theClosure: closure, providesReturnValue: true)
        addAction(action: action)
        return self
    }
    
    func addAction(action: MockAction) {
        actions.append(action);
    }
    
    func performActions() -> Any? {
        var returnValue: Any?
        for action in actions {
            if action.providesReturnValue() {
                returnValue = action.performAction()
            } else {
                action.performAction()
            }
        }
        return returnValue
    }
}

public class MockAction {
    let closure: () -> Any?
    let returnsValue: Bool
    
    init(theClosure: @escaping () -> Any?, providesReturnValue: Bool = false) {
        closure = theClosure
        returnsValue = providesReturnValue
    }
    
    func performAction() -> Any? {
        return closure()
    }
    
    func providesReturnValue() -> Bool {
        return returnsValue
    }
}

extension String {
    func getPatternString(pattern: String) -> String? {
        print("self.substring(with: inputRange) : \(self) : \(pattern)")
        if true{
            return nil
        } else {
            return nil
        }
    }
}


class MockHelper {
    enum MyError: Error {
        case NotAllowed
    }
    var calledFunction: [String] = [String]()
    var verifyCalledFunction: [String] = [String]()
    var stubFunctions: [(String,MockActionable,Bool)] = [(String,MockActionable,Bool)]()
    static let sharedInstance = MockHelper()
    class func verify() -> Bool{
        var returnValue = false
        for (_,ele) in MockHelper.sharedInstance.verifyCalledFunction.enumerated() {
            if MockHelper.sharedInstance.verify(str: ele){
                returnValue = true
            }else{
                returnValue = false
                return returnValue
            }
        }
        MockHelper.sharedInstance.removeAllCalls()
        return returnValue
    }
    class func functionIsGettingCalled(functionName: String) -> (Bool,Any?){
//        let funcName = replaceFunctionName(functionName: functionName)
        MockHelper.sharedInstance.calledFunction.append(functionName)
        var returnValue:Any?
        for stubFunction: (String,MockActionable,Bool) in MockHelper.sharedInstance.stubFunctions{
            if stubFunction.0 == functionName{
                returnValue = stubFunction.1.performActions()
                return (stubFunction.2,returnValue)
            }
        }
        return (false,nil)
    }
    class func expectCall(_ functionName: String){
        MockHelper.sharedInstance.verifyCalledFunction.append(functionName)
    }
    class func stub(_ functionName: String , funcBlock: (()->Any?)? = nil) -> MockActionable{
        let mockActions = MockActionable(funcBlock)
        let overrideFunction = (funcBlock == nil) ? false : true
        MockHelper.sharedInstance.stubFunctions += [(functionName,mockActions,overrideFunction)]
        return mockActions
    }
    class func replaceFunctionName(functionName: String) -> String{
        var functionReturnName = functionName
        if let funcNameReplace = functionName.getPatternString(pattern: "\\(.+"){
            functionReturnName = functionName.replacingOccurrences(of: funcNameReplace, with: "")
        }
        return functionReturnName
    }
    class func mockMyObject<O:AnyObject, C:TestableClass>(_ currentObject: O ,_ mockType: C.Type)->Void {
        if mockType is O.Type{
            object_setClass(currentObject, mockType)
        }
    }
    func verify(str: String)->Bool{
        let itemExists = calledFunction.contains(str)
        return itemExists
    }
    func removeAllCalls(){
        verifyCalledFunction.removeAll(keepingCapacity: false)
        calledFunction.removeAll(keepingCapacity: false)
    }
    
}

let test = mainClass()
MockHelper.mockMyObject(test, testClass.self)
MockHelper.expectCall("testFunction")
MockHelper.expectCall("anotherFunctionWithMultipleParameter")
MockHelper.expectCall("thisAwesomeFunctionWithParameter")
MockHelper.stub("thisAwesomeFunctionWithParameter")
    .andDo{
        print("this is cool 1")
    }
    .andDo{
        print("this is cool 2")
    }
MockHelper.stub("functionWithReturnType")
.andReturn(value: "awesome")
.andDo{
    print("functionWithReturnType andDo")
}
test.thisAwesomeFunctionWithParameter()
test.functionWithReturnType()
MockHelper.verify()
