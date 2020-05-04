/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.webui.components;

 import java.sql.SQLException;
 import java.util.HashMap;
 import java.util.ArrayList;
 import java.util.Map;

 import org.apache.log4j.Logger;

 import org.dspace.content.Community;
 import org.dspace.content.Collection;
 import org.dspace.core.Context;
 import org.dspace.authorize.AuthorizeManager;

/**
 * This class generates list of all collections and communities which are not empty or where the user is administrator or submitter
 *
 * @author Kate Pechekhonova
 *
 */
public class ListUserCommunities {

    // This will map collectionIDs to arrays of collections
    private Map<Integer, Collection[]> colMap;

    // This will map communityIDs to arrays of sub-communities
    private Map<Integer, Community[]> commMap;
    private static final Object staticLock = new Object();

    /** Our context */
    protected Context ourContext;
    private Community ourCommunity;

    /** log4j category */
    private static Logger log = Logger.getLogger(ListUserCommunities.class);

    //used for full community list on home page and list-communities.jsp page
    public  ListUserCommunities(Context context)  throws java.sql.SQLException {

        ourContext = context;

        synchronized (staticLock) {

            colMap = new HashMap<Integer, Collection[]>();
            commMap = new HashMap<Integer, Community[]>();

            Community[] communities = Community.findAllTop(ourContext);

            for (int com = 0; com < communities.length; com++) {
                build(communities[com], ourContext);
            }
        }
    }

    //used to list subcommunities and collections on home-community.jsp page
    public  ListUserCommunities(Context context, Community community)  throws java.sql.SQLException {

        ourContext = context;

        synchronized (staticLock) {

            colMap = new HashMap<Integer, Collection[]>();
            commMap = new HashMap<Integer, Community[]>();

            Community ourCommunity = community;
            Community[] communities = community.getSubcommunities();

            if(communities!=null)
            {
                for (int com = 0; com < communities.length; com++) {
                    build(communities[com], ourContext);
                }
            }
        }
    }

    public Map getCommunitiesMap() {
        return commMap;
    }

    public Map getCollectionsMap() {
        return colMap;
    }

    /**Build list of subcommunities and collections  which specific user can see. All users can see public and NYU-only collections in the list
    Empty and private collections are only included in the collection if the user can add content to the collection. In that case user will see all community tree
     up to the collection.
     Empty communities with no collections will only be visible to community and site admins. special case is Gallatin Syllabi collection which is available to only Gallatin School
     students but is included to the list **/

    void build(Community c, Context context) throws SQLException {
        Integer comID = Integer.valueOf(c.getID());

        // Find collections assosiated with community and if they exist add the community to map
        Collection[] colls = c.getCollections();
        if (colls.length > 0) {
            colMap.put(comID, colls);
        }
        // Find subcommunties in community
        Community[] comms = c.getSubcommunities();

        // Find subcommunities assosiated with community and if they exist add the community to map
        if ( comms.length > 0 || AuthorizeManager.isAdmin(context,c)) {
            commMap.put(comID, comms);

            for (int sub = 0; sub < comms.length; sub++) {

                build(comms[sub], context);
            }
        }


        //if the community does not have assosiated subcomunities and collections which user can see we do not want to display it. To achieve it we need to remove it from the
        // map. It is done in 2 places. We need to remove the community from the list of communities assosiated with it's parent community and also we need to remove the community entry from the Mpa
        // That's what we are doing below in 2 steps

        //Step 1. Remove from the array assosiated with parents community
        if(!AuthorizeManager.isAdmin(context,c)) {
            if (colls.length == 0 && comms.length == 0) {
                Community parentComm = c.getParentCommunity();

                if (parentComm != null) {
                    Integer parentCommID = Integer.valueOf(parentComm.getID());

                    Community[] parentComms = commMap.get(parentCommID);
                    if (parentComms != null) {
                        ArrayList<Community> parentCommsNew = new ArrayList<Community>();

                        for (int i = 0; i < parentComms.length; i++) {

                            if (parentComms[i].getID() != comID) {
                                parentCommsNew.add(parentComms[i]);
                            }
                        }

                        Community[] parentCommsArray = new Community[parentCommsNew.size()];
                        //put modified array back to map. We need to convert that to Array instead of using ArrayList which are logical here because code downstream uses Arrays
                        //and I do not want to re-write it
                        commMap.put(parentCommID, parentCommsNew.toArray(parentCommsArray));
                    }
                }
            }
        }
            //Step 2. If we do not have collections available to the user in the community, check if we have non empty children communities and if we do not and the user is not community admin, remove from the map.

        if (colls.length == 0 && commMap.containsKey(comID) && !AuthorizeManager.isAdmin(context,c)) {
                Community[] commProcessed = commMap.get(comID);

                if (commProcessed != null && commProcessed.length == 0)
                {
                    commMap.remove(comID);
                }
        }

    }

}

