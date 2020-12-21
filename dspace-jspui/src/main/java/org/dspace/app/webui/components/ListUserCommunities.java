/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 * <p>
 * http://www.dspace.org/license/
 */
package org.dspace.app.webui.components;


import java.sql.SQLException;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Map;

import org.apache.log4j.Logger;

import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.Community;
import org.dspace.content.Collection;
import org.dspace.core.Context;
import  org.dspace.eperson.EPerson;

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

    // This will map communityIDs to arrays of sub-communities
    private ArrayList<Collection> nyuOnly;


    // This will map collectionIDs to arrays of collections
    public static Map<Integer, Collection[]> colMapAnon;

    // This will map communityIDs to arrays of sub-communities
    public static Map<Integer, Community[]> commMapAnon;

    private static final Object staticLock = new Object();

    /** Our context */
    protected Context ourContext;


    /** log4j category */
    private static Logger log = Logger.getLogger(ListUserCommunities.class);

    //used for full community list on home page and list-communities.jsp page
    public  ListUserCommunities() {

    }

    public Map getCommunitiesMap() {
        return commMap;
    }

    public Map getCollectionsMap() {
        return colMap;
    }

    public ArrayList<Collection> getNYUOnly() {
        return nyuOnly;
    }

    //used for full community list on home page and list-communities.jsp page for a specific loged in user
    public  ListUserCommunities(Context context) throws java.sql.SQLException {

        ourContext = context;

        colMap = new HashMap<Integer, Collection[]>();
        commMap = new HashMap<Integer, Community[]>();
        nyuOnly = new ArrayList<Collection>();


            Community[] communities = Community.findAll(context);

            //user only can see non-empty, not private collections
            for (int com = 0; com < communities.length; com++) {
                buildCollection(communities[com], context);
            }

            Community[] communitiesAval = Community.findAllTop(context);

            // we only include communities which has collections that the user can see
            for (int com = 0; com < communitiesAval.length; com++) {
                buildCommunity(communitiesAval[com], context);
            }

    }

    //used for subcommunity abd collection list for a specific community for loged on user
    public   ListUserCommunities(Context context, Community c) throws java.sql.SQLException {

        ourContext = context;

        colMap = new HashMap<Integer, Collection[]>();
        commMap = new HashMap<Integer, Community[]>();
        nyuOnly = new ArrayList<Collection>();


        buildCollection(c, context);

        buildList(c, context);
    }

    // used for full community list on home page and list-communities.jsp page for an anonymos user, It is the same for all anonymouse
    // users so we can keep it as static variable for the class and calculate only ones
    public static synchronized void ListAnonUserCommunities(Context context)
            throws java.sql.SQLException {


        if (colMapAnon == null && commMapAnon == null) {

            colMapAnon = new HashMap<Integer, Collection[]>();
            commMapAnon = new HashMap<Integer, Community[]>();

            Community[] communities = Community.findAll(context);

            //user only can see non-empty, not private collections
            for (int com = 0; com < communities.length; com++) {
                buildAnonCollection(communities[com], context);
            }

            Community[] communitiesAval = Community.findAllTop(context);

            // we only include communities which has collections the user can see
            for (int com = 0; com < communitiesAval.length; com++) {
                buildAnonCommunity(communitiesAval[com], context);
            }
        }
    }



    private  void buildCollection(Community c, Context context) throws SQLException {
        Integer comID = c.getID();
        EPerson currentUser= context.getCurrentUser();

        Collection[] colls = c.getCollections();

        if (colls.length > 0) {
            ArrayList<Collection> availableCol = new ArrayList<Collection>();

            for (int i = 0; i < colls.length; i++) {


                if (colls[i].isPublic()) {
                    if(colls[i].countItems() > 0) {
                        availableCol.add(colls[i]);
                    }
                } else {
                /*TODO: we need to add check that it collection is not empty but it is a bit expensive as we can not use countItems() - it only shows number of items available
                            to a specific user.If the user is not login NYUONLY counter will be 0 even if the collection is not empty. Now we do not have empty NYU only collections
                            but it needs to be fixed soon*/
                    if (colls[i].isNYUOnly()) {
                        availableCol.add(colls[i]);
                        nyuOnly.add(colls[i]);

                    } else {

                        if (colls[i].isGallatin()) {
                            availableCol.add(colls[i]);

                        }
                    }
                }

                if (!availableCol.contains(colls[i])&&currentUser != null &&
                        (colls[i].canEditBoolean(true)|| colls[i].getSubmitters().isMember(currentUser))) {
                        availableCol.add(colls[i]);

                }
            }
            if (availableCol.size() > 0) {
                Collection[] availableColArray = new Collection[availableCol.size()];
                colMap.put(comID, availableCol.toArray(availableColArray));
            }
        }

    }

    private  void buildCommunity(Community c, Context context) throws SQLException {
        Integer comID = c.getID();

        Community[] comms = c.getSubcommunities();

        if (comms.length > 0) {
            ArrayList<Community> availableComm = new ArrayList<Community>();

            for (int i = 0; i < comms.length; i++) {

                buildCommunity(comms[i], context);

                if(  colMap.containsKey(comms[i].getID())
                        || (commMap.containsKey(comms[i].getID())|| AuthorizeManager.isAdmin(context,comms[i]))) {
                        availableComm.add(comms[i]);
                    }
            }
            if(availableComm.size()>0 ) {
                Community[] availableCommArray = new Community[availableComm.size()];
                commMap.put(comID, availableComm.toArray(availableCommArray));
            }
        } else {
            if(c.canEditBoolean() ) {
                commMap.put(comID,comms);
            }
        }
    }

    private  void buildList(Community c, Context context) throws SQLException {
        Integer comID = c.getID();


        Community[] comms = c.getSubcommunities();

        if (comms.length > 0) {
            ArrayList<Community> availableComm = new ArrayList<Community>();

            for (int i = 0; i < comms.length; i++) {

                buildCollection(comms[i], context);

                buildList(comms[i],context);

                if( colMap.containsKey(comms[i].getID())
                        || commMap.containsKey(comms[i].getID()) || AuthorizeManager.isAdmin(context,comms[i])) {
                    availableComm.add(comms[i]);
                }

            }
            if(availableComm.size()>0 ) {
                Community[] availableCommArray = new Community[availableComm.size()];
                commMap.put(comID, availableComm.toArray(availableCommArray));
            }
        } else {
            if(c.canEditBoolean() ) {
                commMap.put(comID,comms);
            }
        }
    }

    private static void buildAnonCollection(Community c, Context context) throws SQLException {
        Integer comID = Integer.valueOf(c.getID());

        Collection[] colls = c.getCollections();

        if (colls.length > 0) {
            ArrayList<Collection> availableCol = new ArrayList<Collection>();

            for (int i = 0; i < colls.length; i++) {

                if (!colls[i].isPrivate()&&colls[i].countItems()>0) {
                    availableCol.add(colls[i]);
                }
            }
            if(availableCol.size()>0) {
                Collection[] availableColArray = new Collection[availableCol.size()];
                colMapAnon.put(comID, availableCol.toArray(availableColArray));
            }
        }
    }

    private static void buildAnonCommunity(Community c, Context context) throws SQLException {
        Integer comID = Integer.valueOf(c.getID());

        Community[] comms = c.getSubcommunities();

        if (comms.length > 0) {
            ArrayList<Community> availableComm = new ArrayList<Community>();

            for (int i = 0; i < comms.length; i++) {

                if (colMapAnon.containsKey(Integer.valueOf(comms[i].getID()))) {
                    availableComm.add(comms[i]);
                } else {
                    buildAnonCommunity(comms[i],context);
                    if (commMapAnon.containsKey(Integer.valueOf(comms[i].getID()))) {
                        availableComm.add(comms[i]);
                    }
                }
            }
            if(availableComm.size()>0) {
                Community[] availableCommArray = new Community[availableComm.size()];
                commMapAnon.put(comID, availableComm.toArray(availableCommArray));
            }
        }
    }


}

