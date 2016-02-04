/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.sword;

/**
 * Some URIs for DSpace specific errors which may be reported through the SWORDErrorException
 */
public interface DSpaceSWORDErrorCodes
{
	/** if unpackaging the package fails */
	String UNPACKAGE_FAIL = SWORDProperties.SOFTWARE_URI + "/errors/UnpackageFail";

	/** if the url of the request does not resolve to something meaningful */
	String BAD_URL = SWORDProperties.SOFTWARE_URI + "/errors/BadUrl";

	/** if the media requested is unavailable */
	String MEDIA_UNAVAILABLE = SWORDProperties.SOFTWARE_URI + "/errors/MediaUnavailable";

    /* additional codes */
    
    /** Invalid package */
	String PACKAGE_ERROR = SWORDProperties.SOFTWARE_URI + "/errors/PackageError";
    
    /** Missing resources in package */
	String PACKAGE_VALIDATION_ERROR = SWORDProperties.SOFTWARE_URI + "/errors/PackageValidationError";
    
    /** Crosswalk error */
	String CROSSWALK_ERROR = SWORDProperties.SOFTWARE_URI + "/errors/CrosswalkError";
    
    /** Invalid collection for linking */
	String COLLECTION_LINK_ERROR = SWORDProperties.SOFTWARE_URI + "/errors/CollectionLinkError";
    
    /** Database or IO Error when installing new item */
	String REPOSITORY_ERROR = SWORDProperties.SOFTWARE_URI + "/errors/RepositoryError";

}
