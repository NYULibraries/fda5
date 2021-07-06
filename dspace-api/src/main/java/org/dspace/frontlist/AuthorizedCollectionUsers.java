package org.dspace.frontlist;

/* This class is used to store information on admins of private and empty collections.
 We use event listener which tracks
 when collections change their status (becomes non-empty oor empty, becomes private or public)
 when groups are attached/removed to/from private or empty collections
 when epersons become admins/submitters for private or empty collections or removed from admin/submitters of private or empty collection
 Thus to speed up callculations and insure data integrity we need to store triples <epersonID,groupID,collectionID>
 */
public class AuthorizedCollectionUsers {

    private int epersonID;

    private int groupID;

    private int collectionID;

    public AuthorizedCollectionUsers(int epersonID, int groupID, int collectionID) {
        setCollectionID(collectionID);
        setEpersonID(epersonID);
        setGroupID(groupID);
    }

    public int getEpersonID() {
        return epersonID;
    }

    public void setEpersonID(int epersonID) {
        this.epersonID = epersonID;
    }

    public int getCollectionID() {
        return collectionID;
    }

    public void setCollectionID(int collectionID) {
        this.collectionID = collectionID;
    }

    public int getGroupID() {
        return groupID;
    }

    public void setGroupID(int groupID) {
        this.groupID = groupID;
    }
}
