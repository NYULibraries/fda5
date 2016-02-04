/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.versioning;

import org.dspace.content.Item;
import org.dspace.eperson.EPerson;

import java.util.Date;

/**
 *
 *
 * @author Fabio Bolognesi (fabio at atmire dot com)
 * @author Mark Diggory (markd at atmire dot com)
 * @author Ben Bosman (ben at atmire dot com)
 */
public interface Version
{
    EPerson getEperson();
    int getItemID();
    Date getVersionDate();
    int getVersionNumber();
    String getSummary();
    int getVersionHistoryID();
    int getVersionId();
    Item getItem();
}

