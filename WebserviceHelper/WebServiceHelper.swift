
import Foundation
import UIKit

//MARK: accessToken
let ACCESS_TOKEN = "access_token"
var accessToken :String{
get{
    if NSUserDefaults.standardUserDefaults().valueForKey(ACCESS_TOKEN) == nil {
        return ""
    }
    else {
        return NSUserDefaults.standardUserDefaults().valueForKey(ACCESS_TOKEN) as! String // this should not be nil
    }
}
set(value){
    NSUserDefaults.standardUserDefaults().setValue(value, forKey: ACCESS_TOKEN)
}
}
/**
 *  Delegates for handling webservice response or error
 */
protocol WebServiceHelperDelegate {
    func webServiceHelperApiCallResponse(response: AnyObject!, serviceTag: Int)
    func webServiceHelperApiCallError(error: NSError!, serviceTag: Int)
}

/**
 Self-difined error type
 */
enum JSONError: String, ErrorType {
    case InvalidJson = "ERROR: No Data"
    case ConversionFailed = "ERROR: Conversion from JSON failed"
}

class WebServiceHelper : NSObject{
    var request :NSMutableURLRequest!
    var delegate : WebServiceHelperDelegate!
    var CLIENT_ID = ""
    var SECRET_KEY = ""
    var oAuthManagerAccessToken  = accessToken
    
    let CONTENT_TYPE_URL_ENCODED = "application/x-www-form-urlencoded"
    let CONTENT_TYPE_IMAGE_PNG = "image/png"
    let CONTENT_TYPE_IMAGE_JPG = "image/jpeg"
    let CONTENT_TYPE_MULTIPART_FORM_DATA = "multipart/form-data"
    let ACCEPT_TYPE_JSON = "application/json"
    let METHOD_POST = "POST"
    let METHOD_GET = "GET"
    let METHOD_PUT = "PUT"
    let TIMEOUT_INTERVAL : NSTimeInterval = 90
    
    //String constants To be used
    let HTTP_HEADER_AUTHORIZATION = "Authorization"
    let HTTP_HEADER_CONTENT_TYPE = "Content-Type"
    let HTTP_HEADER_ACCEPT_TYPE = "Accept"
    let STRING_BEARER = "Bearer "
    let STRING_BASIC = "Basic "
    let QUESTION_MARK = "?"
    
    //AUTHORIZATION_HEADER_TYPE
    let AUTHORIZATION_TYPE_BEARER = 88
    let AUTHORIZATION_TYPE_BASIC = 99
    
    //Sometimes for autorisation it is required to have username and password to be base 64 encrypted
    func getBase64StringFromCredential(userName: String, password: String) -> String{
        let basicAuthCredentials = userName + ":" + password
        let plainData = (basicAuthCredentials as NSString).dataUsingEncoding(NSASCIIStringEncoding)
        let base64String = plainData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        return base64String!
    }
    
    /**
     get query string for required dictionary
     
     - parameter parameter: dictioary to be converted for query string
     
     - returns: query string of passed dictionary
     */
    class func getQueryStringWithParameters(parameter: Dictionary<String, AnyObject?>) -> String{
        var resultString = ""
        let BOOLEAN_TRUE_STRING = "1"
        let BOOLEAN_FALSE_STRING = "0"
        
        for (key, value) in parameter {
            var localValue = ""
            if let typeValue = value as? Bool{
                localValue = typeValue ? BOOLEAN_TRUE_STRING : BOOLEAN_FALSE_STRING
            }else if let typeValue = value as? String{
                localValue = typeValue
            }else if let typeValue = value as? Int{
                localValue = String(typeValue)
            }
            resultString += key + "=" + localValue + "&"
        }
        return resultString.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "&"))
    }
    
    /**
     This method is for genreating request with httpBody for given details
     
     - parameter baseUrl:           webservice path url as string type
     - parameter parameter:         parameters to send with request
     - parameter contentType:       contebt type of request
     - parameter acceptType:        response accept type
     - parameter authorizationType: authorization type its bearer or basic
     - parameter method:            requst type with method get, post or put
     */
    func generateRequestWithHTTPBodyForBaseUrl(baseUrl: String,
        parameter: [String: AnyObject]?,
        contentType: String,
        acceptType: String,
        authorizationType: Int,
        method: String){
        
        requestURLAndMethodSetup(baseUrl,method: method)
    
        if let param: AnyObject = parameter {
            request.HTTPBody = param.dataUsingEncoding(NSUTF8StringEncoding)
            print(NSString(data: request.HTTPBody!, encoding:NSUTF8StringEncoding))
        }
        
        requestHeaderSetupWith(contentType, acceptType: acceptType, authorizationType: authorizationType)
    }
    
    /**
     This method is for genreating request without httpBody for given details
     
     - parameter baseUrl:           webservice path url as string type
     - parameter contentType:       contebt type of request
     - parameter acceptType:        response accept type
     - parameter authorizationType: authorization type its bearer or basic
     - parameter method:            requst type with method get, post or put
     */
    func generateRequestWithoutHTTPBodyForBaseUrl(baseUrl: String,
        contentType: String,
        acceptType: String,
        authorizationType: Int,
        method: String){
        let url = NSURL(string: baseUrl)
        request = NSMutableURLRequest(URL: url!)
        request.timeoutInterval = TIMEOUT_INTERVAL
        request.HTTPMethod = method
        
        requestHeaderSetupWith(contentType, acceptType: acceptType, authorizationType: authorizationType)
    }
    
    /**
     Setup request with method and baseurl
     
     - parameter baseUrl: webservice path url as string type
     - parameter method:  requst type with method get, post or put
     */
    func requestURLAndMethodSetup(baseUrl: String, method: String){
        let url = NSURL(string: baseUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
        request = NSMutableURLRequest(URL: url!)
        request.timeoutInterval = TIMEOUT_INTERVAL
        request.HTTPMethod = method
    }
    
    /**
     request with handling authorization type
     
     - parameter contentType:       content type of request
     - parameter acceptType:        accept type of response
     - parameter authorizationType: STRING_BEARER or STRING_BASIC
     */
    func requestHeaderSetupWith(contentType: String, acceptType: String, authorizationType: Int){
        var base64String = getBase64StringFromCredential(CLIENT_ID ,password:SECRET_KEY)
        switch authorizationType {
        case AUTHORIZATION_TYPE_BEARER :
            base64String = STRING_BEARER + oAuthManagerAccessToken
        case AUTHORIZATION_TYPE_BASIC :
            base64String = STRING_BASIC + base64String
        default:
            print("default base64String\(base64String)")
        }
        print("base64String:  \(base64String)")
        request.addValue(base64String, forHTTPHeaderField: HTTP_HEADER_AUTHORIZATION)
        request.addValue(contentType, forHTTPHeaderField: HTTP_HEADER_CONTENT_TYPE)
        request.addValue(acceptType, forHTTPHeaderField: HTTP_HEADER_ACCEPT_TYPE)
    }
    
    /**
     To setup request
     
     - parameter baseUrl:           webservice path url as string type
     - parameter contentType:       content type of request
     - parameter acceptType:        accept type of response
     - parameter authorizationType: STRING_BEARER or STRING_BASIC
     */
    func generateRequestWithoutAuthorizationForBaseUrl(baseUrl: String,
        contentType: String,
        acceptType: String,
        method: String){
        requestURLAndMethodSetup(baseUrl,method: method)
        request.addValue(contentType, forHTTPHeaderField: HTTP_HEADER_CONTENT_TYPE)
        request.addValue(acceptType, forHTTPHeaderField: HTTP_HEADER_ACCEPT_TYPE)
    }
    
    /**
     Call webservice API with given request and service tag
     
     - parameter request:    generated request for webservice call
     - parameter serviceTag: tagging for webservice call for handling their response or errors seperately
     */
    func callWebserviceWithRequest(request : NSMutableURLRequest!, serviceTag :Int){
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, customError -> Void in
            do{
                guard let responseData = data else {throw JSONError.ConversionFailed}
                guard let json = try NSJSONSerialization.JSONObjectWithData(responseData,
                    options: .MutableLeaves) as? NSDictionary else { throw JSONError.InvalidJson }
                
                self.delegate?.webServiceHelperApiCallResponse(json, serviceTag: serviceTag)
                
            } catch let error as JSONError {
                self.delegate?.webServiceHelperApiCallError(error as NSError, serviceTag: serviceTag)
            } catch {
                self.delegate?.webServiceHelperApiCallError(customError, serviceTag: serviceTag)
            }
        })
        
        task.resume()
    }
    
    /**
     Call POST webservice API with authorization for given request and service tag
     
     - parameter request:    generated request for webservice call
     - parameter serviceTag: tagging for webservice call for handling their response or errors seperately
     */
    func callWebserviceForAuthCodeForPostWithBaseUrl(baseUrl :String,
        parameter: [String: AnyObject]?,
        serviceTag : Int, authorizationType: Int){
        
            generateRequestWithHTTPBodyForBaseUrl(baseUrl,
            parameter: parameter,
            contentType: CONTENT_TYPE_URL_ENCODED,
            acceptType: ACCEPT_TYPE_JSON,
            authorizationType: authorizationType,
            method: METHOD_POST)
        
        callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     Call GET webservice API with authorization(header) for given request and service tag
     
     - parameter baseUrl:           webservice path url as string type
     - parameter parameter:         parameters to send with request
     - parameter serviceTag:        tagging for webservice call for handling their response or errors seperately
     - parameter authorizationType: autorization type bearer or basic
     - parameter header:            header arguments
     */
    func callWebserviceForAuthCodeWithForGetWithBaseUrl(baseUrl :String,
        parameter: [String: AnyObject]?,
        serviceTag : Int,
        authorizationType: Int,
        header : AnyObject?){
        
        generateRequestWithHTTPBodyForBaseUrl(baseUrl,
            parameter: parameter,
            contentType: ACCEPT_TYPE_JSON,
            acceptType: ACCEPT_TYPE_JSON,
            authorizationType: authorizationType,
            method: METHOD_GET)
       
        //if header is having parameters
        if let headerParameter :AnyObject = header {
            let header = JSON(headerParameter)
            for (key, subJson): (String, JSON) in header{
                request.addValue(subJson.stringValue, forHTTPHeaderField:key )
            }
        }
        callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     Call PUT webservice API with authorization(header) for given request and service tag
     
     - parameter baseUrl:           webservice path url as string type
     - parameter parameter:         parameters to send with request
     - parameter serviceTag:        tagging for webservice call for handling their response or errors seperately
     - parameter authorizationType: autorization type bearer or basic
     - parameter header:            header arguments
     */
    func callWebserviceForAuthCodeWithForPutWithBaseUrl(baseUrl :String,
        parameter: [String: AnyObject]?,
        serviceTag : Int,
        authorizationType: Int,
        header : AnyObject?){
            
        generateRequestWithHTTPBodyForBaseUrl(baseUrl,
            parameter: parameter,
            contentType: ACCEPT_TYPE_JSON,
            acceptType: ACCEPT_TYPE_JSON,
            authorizationType: authorizationType,
            method: METHOD_PUT)
        
        //if header is having parameters
        if let headerParameter :AnyObject = header {
            let header = JSON(headerParameter)
            for (key, subJson): (String, JSON) in header{
                request.addValue(subJson.stringValue, forHTTPHeaderField:key )
            }
        }
        callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     Call Get webservice API with authorization(header) and without httpbody for given request and service tag
     
     - parameter baseUrl:           webservice path url as string type
     - parameter parameter:         parameters to send with request
     - parameter serviceTag:        tagging for webservice call for handling their response or errors seperately
     - parameter authorizationType: autorization type bearer or basic
     */
    func callWebserviceForGetWithoutHTTPBodyForhBaseUrl(baseUrl :String,
        parameter: Dictionary<String, AnyObject?>?,
        authorizationType: Int, serviceTag: Int){
            
        var urlString = baseUrl
        if let param = parameter {
            urlString = baseUrl + QUESTION_MARK + WebServiceHelper.getQueryStringWithParameters(param)
        }

        generateRequestWithoutHTTPBodyForBaseUrl(urlString,
            contentType: ACCEPT_TYPE_JSON,
            acceptType: ACCEPT_TYPE_JSON,
            authorizationType: authorizationType,
            method: METHOD_GET)
            
        callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     Call Get webservice API without authorization(header) and  httpbody for given request and service tag
     
     - parameter baseUrl:    webservice path url as string type
     - parameter parameter:  to be query string
     - parameter serviceTag: tagging for webservice call for handling their response or errors seperately
     */
    func callWebserviceForGetWithoutAuthorizationForBaseUrl(baseUrl :String,
        parameter: Dictionary<String, AnyObject?>?,
        serviceTag: Int){
            
        var urlString = baseUrl
        if let param = parameter {
            urlString = baseUrl + QUESTION_MARK + WebServiceHelper.getQueryStringWithParameters(param)
        }
        print(urlString)
        generateRequestWithoutAuthorizationForBaseUrl(urlString, contentType: ACCEPT_TYPE_JSON,
            acceptType: ACCEPT_TYPE_JSON,
            method: METHOD_GET)
            
        callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     Call POST webservice API without authorization(header) and  httpbody for given request and service tag
     
     - parameter baseUrl:    webservice path url as string type
     - parameter parameter:  to be query string
     - parameter serviceTag: tagging for webservice call for handling their response or errors seperately
     */
    func callWebserviceForPostWithoutAuthorizationForBaseUrl(baseUrl :String,
        parameter: Dictionary<String, AnyObject?>?,
        serviceTag: Int){
            
            var urlString = baseUrl
            if let param = parameter {
                urlString = baseUrl + QUESTION_MARK + WebServiceHelper.getQueryStringWithParameters(param)
            }
            
            generateRequestWithoutAuthorizationForBaseUrl(urlString, contentType: ACCEPT_TYPE_JSON,
                acceptType: ACCEPT_TYPE_JSON,
                method: METHOD_POST)
            
            callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     Call POST webservice API without authorization(header) and with httpbody for given request and service tag
     
     - parameter baseUrl:    webservice path url as string type
     - parameter parameter:  to be converted parameter as httpBody
     - parameter serviceTag: tagging for webservice call for handling their response or errors seperately
     */
    func callWebserviceForPostWithHttpBodyForBaseUrl(baseUrl :String,
        parameter: Dictionary<String, AnyObject>?,
        serviceTag: Int){
            generateRequestWithoutAuthorizationForBaseUrl(baseUrl, contentType: ACCEPT_TYPE_JSON,
                acceptType: ACCEPT_TYPE_JSON,
                method: METHOD_POST)
            do{
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(parameter!, options: [])
                print(NSString(data:request.HTTPBody!, encoding:NSUTF8StringEncoding))
            } catch let error{
                self.delegate?.webServiceHelperApiCallError(error as NSError, serviceTag: serviceTag)
            }
            
            callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     To Upload image with parameters
     
     - parameter baseUrl:       webservice path url as string type
     - parameter parameter:     parameter to be added in request body
     - parameter imageParamKey: image parameter name
     - parameter image:         image object as UIImage
     - parameter serviceTag:    tagging for webservice call for handling their response or errors seperately
     */
    @objc func uploadImageWebserviceForPostWithoutAuthorizationForBaseUrl(baseUrl :String, parameter: Dictionary<String,AnyObject>?,imageParamKey: String, image: UIImage, serviceTag: Int){
        let url = NSURL(string: baseUrl)
        request = NSMutableURLRequest(URL: url!)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        requestSetupForUploadImageWithParams(parameter, imageParamKey: imageParamKey, imageName: "weboImage.png", image: image, imageContentType: CONTENT_TYPE_IMAGE_PNG, requestContentType: CONTENT_TYPE_MULTIPART_FORM_DATA)
        print(reqBody)
        print(request.allHTTPHeaderFields)
        if let str = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding) as? String {
            print(str)
        } else {
            print("not a valid UTF-8 sequence")
        }
        
        callWebserviceWithRequest(request, serviceTag: serviceTag)
    }
    
    /**
     setup request for uploading image with parameter
     
     - parameter parameters:         parameter to be added in request body
     - parameter imageParamKey:      image parameter name
     - parameter imageName:          file name to be added in request body
     - parameter image:              image object as UIImage
     - parameter imageContentType:   image/png or image/jpg
     - parameter requestContentType: multipart/form-data
     */
    func requestSetupForUploadImageWithParams(parameters: Dictionary<String,AnyObject>?, imageParamKey:String, imageName : String, image:UIImage, imageContentType : String, requestContentType: String) {
        let boundery: String =  generateBoundaryString()
  
        //convert UIImage to NSData
        let data:NSData = UIImagePNGRepresentation(image)!
        let body:NSMutableData = NSMutableData();
        // with other params
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundery)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        // set upload image, name is the key of image
        body.appendString("--\(boundery)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(imageParamKey)\"; filename=\"\(imageName)\"\r\n")
        body.appendString("Content-Type: \(imageContentType)\r\n\r\n")
        body.appendData(data)
        body.appendString("\r\n")
        body.appendString("--\(boundery)--\r\n")
        
        let content:String = "\(requestContentType); boundary=\(boundery)"
        
        request.timeoutInterval = TIMEOUT_INTERVAL
        request.HTTPMethod = METHOD_POST
        request.setValue(content, forHTTPHeaderField: "Content-Type")
        request.addValue(ACCEPT_TYPE_JSON, forHTTPHeaderField: "Accept")
        request.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
        print(NSString(data: body, encoding: NSUTF8StringEncoding))
        request.HTTPBody = body
        print(request)
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }

}

var reqBody = ""

extension NSMutableData {

    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
        reqBody = reqBody + string
    }
}