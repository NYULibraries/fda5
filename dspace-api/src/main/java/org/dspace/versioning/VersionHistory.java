/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.versioning;

import java.util.List;

/**
 *
 *
 * @author Fabio Bolognesi (fabio at atmire dot com)
 * @author Mark Diggory (markd at atmire dot com)
 * @author Ben Bosman (ben at atmire dot com)
 */
public interface VersionHistory {

    Version getLatestVersion();
    Version getFirstVersion();
    List<Version> getVersions();
    int getVersionHistoryId();
    Version getPrevious(Version version);
    Version getNext(Version version);
    boolean hasNext(Version version);
    void add(Version version);
    Version getVersion(org.dspace.content.Item item);
    boolean hasNext(org.dspace.content.Item item);
    boolean isFirstVersion(Version version);
    boolean isLastVersion(Version version);
    void remove(Version version);
    boolean isEmpty();
    int size();
}
