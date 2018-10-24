/**
 * Created by isaac on 9/28/17.
 */
@isTest
global class HttpRemoteCalloutMock implements HttpCalloutMock {
    global static HTTPResponse respond(HttpRequest req) {

        System.assertEquals('http://13.64.71.110/api/patient/searchProviderByLastName?lastName=Smith', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.SetBody('[{'
                + '"DocKey": 593,'
                + '"LastName": "BLACKSMITH",'
                + '"MiddleName": "E",'
                + '"FirstName": "JAMES",'
                + '"Address1": "689 YORKTOWN RD",'
                + '"Address2": null,'
                + '"City": "LEWISBERRY",'
                + '"State": "PA",'
                + '"PostalCode": "173399258 ",'
                + '"DoctorGrp": null,'
                + '"FacilityKey": null,'
                + '"MarketRepKey": null,'
                + '"PhoneNumber1": "7179324050",'
                + '"FaxNumber": "7179328072",'
                + '"Title": "D.O.      ",'
                + '"Suffix": null,'
                + '"UPIN": "          ",'
                + '"MedicalID": "101042848",'
                + '"DEANumber": null,'
                + '"User1": null,'
                + '"User2": null,'
                + '"Note": null,'
                + '"LicenseExpiryDate": null,'
                + '"MobilePhone": null,'
                + '"EmailAddress": null,'
                + '"StateMedicaidID": null,'
                + '"NPINumber": "1609832104"'
                + '}, {'
                + '"DocKey": 1160,'
                + '"LastName": "COLBY SMITH",'
                + '"MiddleName": null,'
                + '"FirstName": "DENNIS",'
                + '"Address1": "10769 14TH AVE",'
                + '"Address2": null,'
                + '"City": "ARMONA",'
                + '"State": "CA",'
                + '"PostalCode": "932020000 ",'
                + '"DoctorGrp": null,'
                + '"FacilityKey": null,'
                + '"MarketRepKey": null,'
                + '"PhoneNumber1": "5595837200",'
                + '"FaxNumber": "5595837609",'
                + '"Title": "MD        ",'
                + '"Suffix": null,'
                + '"UPIN": "A28690    ",'
                + '"MedicalID": "A40293",'
                + '"DEANumber": "AB2480426",'
                + '"User1": null,'
                + '"User2": null,'
                + '"Note": "HAS NO STATE LIC AT THIS TIME",'
                + '"LicenseExpiryDate": null,'
                + '"MobilePhone": null,'
                + '"EmailAddress": null,'
                + '"StateMedicaidID": null,'
                + '"NPINumber": "1952447955"'
                + '}, {'
                + '"DocKey": 1503,'
                + '"LastName": "DONAHUE-SMITH",'
                + '"MiddleName": null,'
                + '"FirstName": "CATHERINE",'
                + '"Address1": "3506 KENNETT PIKE",'
                + '"Address2": null,'
                + '"City": "WILMINGTON",'
                + '"State": "DE",'
                + '"PostalCode": "19807     ",'
                + '"DoctorGrp": null,'
                + '"FacilityKey": null,'
                + '"MarketRepKey": null,'
                + '"PhoneNumber1": "3028384774",'
                + '"FaxNumber": "3028384793",'
                + '"Title": "MD        ",'
                + '"Suffix": null,'
                + '"UPIN": "          ",'
                + '"MedicalID": null,'
                + '"DEANumber": null,'
                + '"User1": null,'
                + '"User2": null,'
                + '"Note": null,'
                + '"LicenseExpiryDate": null,'
                + '"MobilePhone": null,'
                + '"EmailAddress": null,'
                + '"StateMedicaidID": null,'
                + '"NPINumber": "1124099973"'
                + '}]');
        res.setStatusCode(200);

        return res;
    }

    global static HTTPResponse timeoutResponse(HttpRequest req) {

        System.assertEquals('http://13.64.71.110/api/patient/searchProviderByLastName?lastName=Smith', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.SetBody('[{"foo":"bar"}]');
        res.setStatusCode(400);

        return res;
    }
}