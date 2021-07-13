/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 * <p>
 * http://www.dspace.org/license/
 */
package org.dspace.frontlist;


import java.sql.SQLException;
import java.util.Iterator;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentMap;
import java.util.LinkedList;
import java.util.Arrays;

import org.apache.log4j.Logger;

import org.dspace.content.Community;
import org.dspace.content.Collection;
import org.dspace.content.DSpaceObject;
import org.dspace.core.Constants;
import org.dspace.core.Context;
import org.dspace.eperson.EPerson;
import org.dspace.eperson.Group;

/**
 * This class generates list of collections and communities which will be listed on home page and on community pages
 * Anonymous users can only see - public, NYU only and school specific (Gallatin) collection which are not empty.
 * Collection, community and site admins can see empty and private collections which they administrate. Also submitters
 * can see empty collections to which they can add items.
 * We make all initial calculations when dspace-jspui application starts and then do updates when changes are made:
 * when items are added to empty collection,
 * when all items are removed from collection,
 * when new admins are added or removed for private collections,
 * when collection permissions are modified,
 * when collections and communities are added or removed
 * All those objects are used By Classes
 * ListCommunitiesSiteProcessor to generate site home page (objects will be passed to home.jsp as attributes)
 * ListCommunitiescomminityProcessor to generate community home page (objects will be passed to community-home.jsp as attributes)
 * ComminityListServlet to generate communities and collection lists (objects will be passed to community-list.jsp as attributes)
 * @author Kate Pechekhonova
 *
 */
public class ListUserCommunities {


    // This contains list of NYU only collections IDs
    public static CopyOnWriteArrayList<Integer> nyuOnly;

    // This contains list of Gallatin only collectiuons IDs
    public static CopyOnWriteArrayList<Integer> gallatinOnly;

    // This contains list of empty collections IDs
    public static CopyOnWriteArrayList<Integer> emptyCollections;

    // This contains list of private collections IDs
    public static CopyOnWriteArrayList<Integer> privateCollections;

    // This will map parent communityIDs to arrays of collections for all
    // publicly available (not private and not empty) collections
    public static ConcurrentMap<Integer, Collection[]> colMapAnon;

    // This will map parent communityIDs to arrays of sub-communities for all
    // publicly available (not private and not empty) collections
    public static ConcurrentMap<Integer, Community[]> commMapAnon;

    // This will map all parent communityIDs to arrays of all  collections
    public static ConcurrentMap<Integer, Collection[]> colMapAdmin;

    // This will map all parent communityIDs to arrays of all sub-communities
    public static ConcurrentMap<Integer, Community[]> commMapAdmin;

    // This contains  list of triples <epersonID,groupID,collectionID> for empty and private collection admins
    public static CopyOnWriteArrayList<AuthorizedCollectionUsers> colAuthorizedUsers;

    // This contains  list of triples <epersonID,groupID,communityID> for empty and private community admins
    public static CopyOnWriteArrayList<AuthorizedCommunityUsers> commAuthorizedUsers;

    // This contains temporary list of triples <epersonID,groupID,collectionID> for empty and private collection admins
    // It will be used for initial calculations as CopyOnWriteArrayList creates new copy each time "write" operation is performed
    // so is not suitable for many inserts
    public static ArrayList<AuthorizedCollectionUsers> colAuthorizedUsersRaw;

    // This contains temporary list of triples <epersonID,groupID,communityID> for empty and private community admins
    // It will be used for initial calculations as CopyOnWriteArrayList creates new copy each time "write" operation is performed
    // so is not suitable for many inserts
    public static ArrayList<AuthorizedCommunityUsers> commAuthorizedUsersRaw;


    /**
     * Our context
     */
    protected Context ourContext;


    /**
     * log4j category
     */
    private static Logger log = Logger.getLogger(ListUserCommunities.class);



    public void ListUserCommunities() {

    }

    //generates maps for anon user, for site admins and other strucrtures which will be used to get tailored community lists for different users
    public static  void PrebuildFrontListsCommunities() throws SQLException {

        Context context = new Context();

        if( colMapAnon==null && commMapAnon==null) {

            colMapAnon = new ConcurrentHashMap<Integer, Collection[]>();
            commMapAnon = new ConcurrentHashMap<Integer, Community[]>();
            colMapAdmin = new ConcurrentHashMap<Integer, Collection[]>();
            commMapAdmin = new ConcurrentHashMap<Integer, Community[]>();
            colAuthorizedUsersRaw = new ArrayList<AuthorizedCollectionUsers>();
            commAuthorizedUsersRaw = new ArrayList<AuthorizedCommunityUsers>();
            colAuthorizedUsers = new CopyOnWriteArrayList<AuthorizedCollectionUsers>();
            commAuthorizedUsers = new CopyOnWriteArrayList<AuthorizedCommunityUsers>();
            nyuOnly = new  CopyOnWriteArrayList<Integer>();
            gallatinOnly = new  CopyOnWriteArrayList<Integer>();
            privateCollections = new  CopyOnWriteArrayList<Integer>();
            emptyCollections = new  CopyOnWriteArrayList<Integer>();

            // Build admin and general maps of collection for each  community.
            // In the process of building maps we will also build nyuOnly, gallatinOnly,
            // privateCollections, emptyCollections which will allow us to make faster calculations
            // We also will build an ArrayList of class AuthorizedCoolectionUsers
            // The later will be used to build user specific front list for collection admins
            Community[] communities = Community.findAll(context);

            if(communities!=null) {
                //user only can see non-empty, not private collections
                for (int com = 0; com < communities.length; com++) {
                    buildCollections(communities[com]);
                }
            }

            //Build admin and general list of subcommunities for each community.
            //In the process of building maps we will also build ArrayList of class AuthorizedCommunityUsers.
            // It will be used to build user specific front list for community admins.
            // We will be using recrussion so here we start with Top level communities
            Community[] communitiesAval = Community.findAllTop(context);

            if(communitiesAval!=null) {
                for (int com = 0; com < communitiesAval.length; com++) {
                    buildCommunity(communitiesAval[com]);
                }
            }

            //convert ArrayLists for private and empty collections/communities admins to CopyOnWriteArrayList to make it threadsafe
              colAuthorizedUsers = new CopyOnWriteArrayList<AuthorizedCollectionUsers>(colAuthorizedUsersRaw);
              log.debug("size of authorized collection list"+colAuthorizedUsers.size());
              commAuthorizedUsers = new CopyOnWriteArrayList<AuthorizedCommunityUsers>(commAuthorizedUsersRaw);
              log.debug("size of authorized community list"+commAuthorizedUsers.size());
    }

    }

    /****Methods needed to build pre-calculated objects****/

    /* Build admin and non-admin maps of collection for each  community.
     * In the process of building maps we will also build nyuOnly, gallatinOnly,
     * privateCollections, emptyCollections which will allow us to make faster calculations
     * We also will build an ArrayLists of classes AuthorizedCoolectionUsers and AuthorizedCommunityUsers-
     * The later will be used to build user specific front list for collection admins
     * Takes parent community as input
     */

    /*Builds subcommunity map, e.g. map where each entry looks like <key=Parent Community ID, value=[Children Subcommunties of this community]
     *@param Community
     */
    private static void buildCollections(Community c) throws SQLException {

        Integer comID = c.getID();
        Collection[] colls = c.getCollections();
        log.debug("collection array length: "+colls.length);

        //build admin map
        colMapAdmin.put(comID, colls);
        log.debug("community used: "+c.getName()+" size: "+ colMapAdmin.get(comID).length);

        if (colls.length > 0) {
            ArrayList<Collection> availableCol = new ArrayList<Collection>();


            for (int i = 0; i < colls.length; i++) {

                int countItems = colls[i].countItems();
                int colID = colls[i].getID();
                if (colls[i].isPublic()) {
                    if(countItems>0) {
                        availableCol.add(colls[i]);
                    } else {
                        emptyCollections.add(colID);
                    }
                } else {
                    if (colls[i].isNYUOnly()) {
                        if(countItems>0) {
                            availableCol.add(colls[i]);
                        } else {
                            emptyCollections.add(colID);
                        }
                        nyuOnly.add(colID);

                    } else {

                        if (colls[i].isGallatin()) {
                            if(countItems>0) {
                                availableCol.add(colls[i]);
                            } else {
                                emptyCollections.add(colID);
                            }
                            gallatinOnly.add(colID);
                        }
                    }
                }

                if (!availableCol.contains(colls[i])) {

                    buildAuthorizedColList(colls[i]);

                    if(colls[i].isPrivate()) {
                        privateCollections.add(colID);
                    }
                    if(countItems==0) {
                        emptyCollections.add(colID);
                    }

                }
            }
            //if community has publicly available collection(s) add it to non-admin map
            if (availableCol.size() > 0) {
                Collection[] availableColArray = new Collection[availableCol.size()];
                colMapAnon.put(comID, availableCol.toArray(availableColArray));
            }
        }

    }

    /*Builds collection map, e.g. map where each entry looks like <key=Parent Community ID, value=[Children Collections of this community]
    *@param Community
    */
    private static void buildCommunity(Community c) throws SQLException {
        Integer comID = c.getID();
        Community[] comms = c.getSubcommunities();
        log.debug("community array length: "+comms.length);

        commMapAdmin.put(comID, comms);
        log.debug("community: "+c.getName()+" size: "+ commMapAdmin.get(comID).length);

        if (comms.length > 0) {
            ArrayList<Community> availableComm = new ArrayList<Community>();

            for (int i = 0; i < comms.length; i++) {

                buildCommunity(comms[i]);

                if (colMapAnon.containsKey(comms[i].getID())
                        || commMapAnon.containsKey(comms[i].getID())) {
                    availableComm.add(comms[i]);
                //if community has only private and non-empty collections or subcommunities we need to add it's admins to
                //authorized community admins list so they can see it in the list
                } else {
                    log.debug("community which is private or empty "+c.getName());
                    buildAuthorizedCommList(comms[i]);
                }
            }
            //if community has public,nyuonly,gallatinonly and non-empty collections or subcommunities we need to add them to generic list
            if (availableComm.size() > 0) {
                Community[] availableCommArray = new Community[availableComm.size()];
                commMapAnon.put(comID, availableComm.toArray(availableCommArray));
            }
        }
    }


    /*get all users who might have admin access to the collection
    *they might be collection admins or submitters or parent community admins
    * @param Collection
    */
    private static void buildAuthorizedColList(Collection col) throws SQLException {

        log.debug("get admins for collection "+col.getName()+" which is private or empty ");
        Group admins = col.getAdministrators();
        if(admins!=null) {
              buildAuthorizedGroupUsers(admins,col);
        }

        Group submitters = col.getSubmitters();
        if(submitters!=null) {
              buildAuthorizedGroupUsers(submitters,col);
        }

        Community[] parentComms = col.getCommunities();
        for(Community  parentComm:parentComms) {
              buildCommGroupUsers(parentComm,col);
        }

    }

    /*get all users who might have admin access to the community
     *they might be community admins or  parent communities admins
     * @param Community */
    private static void buildAuthorizedCommList(Community com) throws SQLException {

        log.debug("get admins for community "+com.getName()+" which is private or empty ");
        Group admins = com.getAdministrators();
        if(admins!=null) {
            buildAuthorizedGroupUsers(admins,com);
        }

        Community[] parentComms = com.getAllParents();
        for(Community  parentComm:parentComms) {
            buildCommGroupUsers(parentComm,com);
        }
    }

    /*get all admins for  parent community of collection or subcommunity
     * @param Parent Community
     * @param  Child Dspace object (collection or community)
     */
    private static void buildCommGroupUsers(Community com,DSpaceObject ds) throws SQLException {
        log.debug("get object type"+ds.getType()+" "+ds.getName()+" which is private or empty ");
        Group admins = com.getAdministrators();
        if(admins!=null) {
            buildAuthorizedGroupUsers(admins,ds);
        }
    }

    /*Add values to colAuthorizedUsersRaw and commAuthorizedUsersRaw ArrayLists which will be at the end converted to WriteOnCopyArrayLists
     *@param Group
     *@param DSpaceObject*/
    private static void buildAuthorizedGroupUsers(Group g,DSpaceObject ds) {

        if(ds.getType()==Constants.COLLECTION) {
            for (EPerson eperson : g.getMembers()) {
                colAuthorizedUsersRaw.add(new AuthorizedCollectionUsers(eperson.getID(), g.getID(), ds.getID()));
                log.debug(" we added eperson "+eperson.getName()+" group "+g.getName()+" object of type"+ds.getType()+" "+ds.getName());
            }
            for (Group ag : g.getMemberGroups()) {
                for (EPerson geperson : ag.getMembers()) {
                    colAuthorizedUsersRaw.add(new AuthorizedCollectionUsers(geperson.getID(), g.getID(), ds.getID()));
                    log.debug(" we added eperson from group "+geperson.getName()+" group "+g.getName()+" object of type"+ds.getType()+" "+ds.getName());
                }

            }
        }

        if(ds.getType()==Constants.COMMUNITY) {
            for (EPerson eperson : g.getMembers()) {
                commAuthorizedUsersRaw.add(new AuthorizedCommunityUsers(eperson.getID(), g.getID(), ds.getID()));
                log.debug(" we added eperson "+eperson.getName()+" group "+g.getName()+" object of type"+ds.getType()+" "+ds.getName());
            }
            for (Group ag : g.getMemberGroups()) {
                for (EPerson geperson : ag.getMembers()) {
                    commAuthorizedUsersRaw.add(new AuthorizedCommunityUsers(geperson.getID(), g.getID(), ds.getID()));
                    log.debug(" we added eperson from group "+geperson.getName()+" group "+g.getName()+" object of type"+ds.getType()+" "+ds.getName());
                }

            }
        }
    }

    /*** Methods used to build communties and collections list for admins of private or/and empty communties/collections***/

    /*Returns array of private and empty collection's ids for which user has admin access.
    * Takes epersonId as a parameter and get data from static CopyOnWriteArrayList<AuthorizedCollectionUsers> colAuthorizedUsers
    *@param epersonID*/
    public static ArrayList getAuthorizedCollections(int epersonID) {
        ArrayList colIDs = new ArrayList();
        Iterator iteratorAuthCollections = colAuthorizedUsers.iterator();
        while (iteratorAuthCollections.hasNext()) {
            AuthorizedCollectionUsers authCol = (AuthorizedCollectionUsers) iteratorAuthCollections.next();
            if(authCol.getEpersonID()==epersonID) {
                    log.debug("collection available to user "+authCol.getCollectionID());
                    colIDs.add(authCol.getCollectionID());
            }

        }
        return colIDs;
    }

    /*Returns if user has admin access to any private or empty collection.
     * Gets data from static CopyOnWriteArrayList<AuthorizedCollectionUsers> colAuthorizedUsers
     *@param epersonID*/
    public static Boolean checkAuthorizedCollections(int epersonID) {
        Iterator iteratorAuthCollections = colAuthorizedUsers.iterator();
        while (iteratorAuthCollections.hasNext()) {
            AuthorizedCollectionUsers authCol = (AuthorizedCollectionUsers) iteratorAuthCollections.next();
            if(authCol.getEpersonID()==epersonID) {
                log.debug("collection available to user on check "+authCol.getCollectionID());
                return true;
            }

        }
        return false;
    }

    /*Returns array of private and empty subcommunities ids for which user has admin access.
     *Get data from static CopyOnWriteArrayList<AuthorizedCommunityUsers> commAuthorizedUsers
     *@param epersonID*/
    public static  ArrayList getAuthorizedCommunities(int epersonID)  {
        ArrayList comIDs = new ArrayList();
        Iterator iteratorAuthCommunities = commAuthorizedUsers.iterator();
        log.debug(" Size of authorized communities ArrayList size "+commAuthorizedUsers.size());
        while (iteratorAuthCommunities.hasNext()) {
            AuthorizedCommunityUsers authComm = (AuthorizedCommunityUsers) iteratorAuthCommunities.next();
            if(authComm.getEpersonID()==epersonID) {
                    log.debug("community available to user "+authComm.getCommunityID());
                    comIDs.add(authComm.getCommunityID());
            }

        }
        return comIDs;
    }

    /*Returns array of private and empty subcommunities ids for which user has admin access.
    * Gets data from static CopyOnWriteArrayList<AuthorizedCommunityUsers> commAuthorizedUsers
    *@param personID */
    public static Boolean checkAuthorizedCommunities(int epersonID)  {
        Iterator iteratorAuthCommunities = commAuthorizedUsers.iterator();
        log.debug(" Size of authorized communities ArrayList check "+commAuthorizedUsers.size());
        while (iteratorAuthCommunities.hasNext()) {
            log.debug(" Authorized communities ArrayList start iteration ");
            AuthorizedCommunityUsers authComm = (AuthorizedCommunityUsers) iteratorAuthCommunities.next();
            log.debug(" Authorized communities ArrayList get value to check "+authComm.getEpersonID());
            if(authComm.getEpersonID()==epersonID) {
                log.debug("community available to user on check "+authComm.getCommunityID());
                return true;
            }

        }
        return false;
    }

    /*** Methods used to manage communites and subcommunities added and removed during the application life cucle ***/

    /*Removes entry for the community and it's children objects from non-admin maps
     *@param comminityID*/
    public static void removeChildrenCommunityFromAnnonListID(int communityID)throws SQLException {
        removeChildrenCommID(communityID,false);
    }
    /*Removes entry for the community and it's children objects from admin maps and list of special admins
     *@param comminityID*/
    public static void removeChildrenCommunityFromAdminListID(int communityID)throws SQLException {
        removeFromCommunityAdminByCommID(communityID);
        removeChildrenCommID(communityID,true);
    }
    /*Removes subcommunity from parent entry in non-admin map
     *@param parentCommID
     *@param communityID */
    public static void   removeSubcommunityFromParentAnnonListID(int parentCommID, int communityID) throws SQLException {
        removeParentCommID(parentCommID, communityID,false);
    }

    /*Removes subcommunity from parent entry in admin map
     *@param parentCommID
     *@param communityID */
    public static void   removeSubcommunityFromParentAdminListID(int parentCommID, int communityID)throws SQLException {
        removeParentCommID(parentCommID, communityID,true);
    }

    /*Removes subcommunity from the array which is assosiated with it's parent community in admin or non-admin map using it's id
     *@param parentCommID
     *@param communityID
     *@param admin*/
    private static void removeParentCommID(int parentCommID, int communityID, Boolean admin ) throws SQLException {
        if(admin) {
            if (commMapAdmin.containsKey(parentCommID) && commMapAdmin.get(parentCommID) != null) {
                Community[] commsOld = commMapAdmin.get(parentCommID);
                LinkedList<Community> commsOldRaw = new LinkedList(Arrays.asList(commsOld));
                for (Community comm: commsOldRaw) {
                    if(comm.getID()==communityID) {
                        commsOldRaw.remove(comm);
                        if (commsOldRaw.size() > 0) {
                            Community[] commNew = new Community[commsOldRaw.size()];
                            commMapAdmin.put(parentCommID, commsOldRaw.toArray(commNew));
                        } else {
                            commMapAdmin.remove(parentCommID);
                            removeFromCommunityAdminByCommID(communityID);
                        }
                    }
                }
            }
        } else {
            if (commMapAnon.containsKey(parentCommID) && commMapAnon.get(parentCommID) != null) {
                Community[] commsOld = commMapAnon.get(parentCommID);
                LinkedList<Community> commsOldRaw = new LinkedList(Arrays.asList(commsOld));
                for (Community comm: commsOldRaw) {
                    if(comm.getID()==communityID) {
                        commsOldRaw.remove(comm);
                        if (commsOldRaw.size() > 0) {
                            Community[] commNew = new Community[commsOldRaw.size()];
                            commMapAnon.put(parentCommID, commsOldRaw.toArray(commNew));
                        } else {
                            commMapAnon.remove(parentCommID);
                        }
                    }
                }
            }
        }
    }
    /*Removes entry for community from collection and community maps when the community is removed.
     *We are not removing entries for children subcommunities but it does not matter because we won't get to them if entry
     *for the parent community is removed
     *@param comminityID
     * @param admin
     */
    private static void removeChildrenCommID(int communityID, Boolean admin) throws SQLException {
        if(admin) {
            if (commMapAdmin!=null && commMapAdmin.containsKey(communityID)) {
                Community[] comms = commMapAdmin.get(communityID);
                if(comms.length>0) {
                    for (Community comm: comms) {
                        removeChildrenCommID(comm.getID(), true);
                    }
                }
                removeFromCommunityAdminByCommID(communityID);
                commMapAdmin.remove(communityID);
            }
            if (colMapAdmin!=null && colMapAdmin.containsKey(communityID)) {
                Collection[] cols = colMapAdmin.get(communityID);
                for(Collection col:cols) {
                    removeFromCollectionAdminByColID(col.getID());
                }
                colMapAdmin.remove(communityID);
            }
        } else {
            if (commMapAnon!=null && commMapAnon.containsKey(communityID) ) {
                commMapAnon.remove(communityID);
            }
            if (colMapAnon!=null && colMapAdmin.containsKey(communityID)) {
                colMapAnon.remove(communityID);
            }

        }

    }
    /*Removes entries from authorized communities  admin list when community is removed
     *@param communityID*/
    private static void removeFromCommunityAdminByCommID(int communityID){
        if (commMapAdmin!=null && commMapAdmin.containsKey(communityID) ) {
            Community[] comms = commMapAdmin.get(communityID);
            for( Community comm:comms) {
                if (commMapAdmin!=null && commMapAdmin.containsKey(comm.getID())) {
                    removeFromCommunityAdminByCommID(comm.getID());
                }
                if (colMapAdmin!=null && colMapAdmin.containsKey(comm.getID())) {
                    Collection[] cols = colMapAdmin.get(comm.getID());
                    for(Collection col:cols) {
                        removeFromCollectionAdminByColID(col.getID());
                    }
                }
            }
            if( commAuthorizedUsers!=null) {
                Iterator iteratorAuthCommunities = commAuthorizedUsers.iterator();
                while (iteratorAuthCommunities.hasNext()) {
                    AuthorizedCommunityUsers authComm = (AuthorizedCommunityUsers) iteratorAuthCommunities.next();
                    if (authComm.getCommunityID() == communityID) {
                        log.debug("collection entry to remove " + authComm.getCommunityID());
                        commAuthorizedUsers.remove(authComm);
                    }

                }
            }
        }
    }
    /*Adds community to admin map. It will happen immediately after the community is created and because it is yet empty it will be
     *only visible to admins. According to FDA policy we won't have private communities so community admins will remain in authorized users list only
     *till we add a non-empty, public collection to the community.
     *@param Community*/
    public static void addCommunityToAdminMap(Community comm) throws SQLException {
        //first add the community to admin community map
        addParentComm(comm, true);
        //add community admins to the authorized list
        buildAuthorizedCommList(comm);
    }
    /*Adds community to non-admin map. It will happen only after the following conditions are met:
    * A collection is added to the community or it's subcommunities
    * That collection is not private
    * At least one item is added to that collection.
    * We will take care of authorized commmunity admins on collection level
    * @param Community*/
    public static void addCommunityToAnonMap(Community comm) throws SQLException {
        addParentComm(comm, false);
    }
    /*Makes actual calculations to add parent community to admin or non-admin map */
    private static void addParentComm( Community comm, Boolean admin ) throws SQLException {
        Community parentComm = (Community) comm.getParentCommunity();
        log.debug(" Community we are adding "+comm.getName());
        if(parentComm!=null) {
            log.debug(" Adding subcommunity to community "+parentComm.getName());
            if(admin) {
                if (commMapAdmin.containsKey(parentComm.getID()) && commMapAdmin.get(parentComm.getID()) != null) {
                    Community[] commsOld = commMapAdmin.get(parentComm.getID());
                    LinkedList<Community> commsOldRaw = new LinkedList(Arrays.asList(commsOld));
                    if (!commsOldRaw.contains(comm)) {
                        commsOldRaw.add(comm);
                        Community[] commNew = new Community[commsOldRaw.size()];
                        commMapAdmin.put(parentComm.getID(), commsOldRaw.toArray(commNew));
                    }
                } else {
                    Community[] commNew = {comm};
                    commMapAdmin.put(parentComm.getID(), commNew);
                }
            } else {
                if (commMapAnon.containsKey(parentComm.getID()) && commMapAnon.get(parentComm.getID()) != null) {
                    Community[] commsOld = commMapAnon.get(parentComm.getID());
                    LinkedList<Community> commsOldRaw = new LinkedList(Arrays.asList(commsOld));
                    if (!commsOldRaw.contains(comm)) {

                        commsOldRaw.add(comm);

                        Community[] commNew = new Community[commsOldRaw.size()];
                        commMapAnon.put(parentComm.getID(), commsOldRaw.toArray(commNew));
                    }
                } else {
                    Community[] commNew = {comm};
                    commMapAnon.put(parentComm.getID(), commNew);
                }
            }
            Community nextParentComm = parentComm.getParentCommunity();
            if (nextParentComm != null) {
                log.debug("Adding next level parent community "+nextParentComm.getName());
                addParentComm(parentComm, admin);
            }
        } else {
            if(admin) {
                log.debug(" Adding top level community to admin map"+comm.getName());
                commMapAdmin.put(comm.getID(), null);
            } else {
                log.debug(" Adding top level community to non-admin map"+comm.getName());
                commMapAnon.put(comm.getID(), null);
            }
        }
    }
    /*if subcommunty metadata was updated, update it in the map*/
    public static  void updateCommunityMetadata( Community comm ) throws java.sql.SQLException {
        Community parentComm = (Community) comm.getParentCommunity();
        if (parentComm != null) {
            if (commMapAdmin.containsKey(parentComm.getID()) && commMapAdmin.get(parentComm.getID()) != null) {
                Community[] commsOld = commMapAdmin.get(parentComm.getID());
                LinkedList<Community> commsOldRaw = new LinkedList(Arrays.asList(commsOld));
                for (Community com : commsOld) {
                    if (com.getID() == comm.getID())
                        commsOldRaw.remove(comm);
                }
                commsOldRaw.add(comm);
                Community[] commNew = new Community[commsOldRaw.size()];
                commMapAdmin.put(parentComm.getID(), commsOldRaw.toArray(commNew));
            }
            if (commMapAnon.containsKey(parentComm.getID()) && commMapAnon.get(parentComm.getID()) != null) {
                Community[] commsOld = commMapAnon.get(parentComm.getID());
                LinkedList<Community> commsOldRaw = new LinkedList(Arrays.asList(commsOld));
                for (Community com : commsOld) {
                    if (com.getID() == comm.getID())
                        commsOldRaw.remove(comm);
                }
                commsOldRaw.add(comm);
                Community[] commNew = new Community[commsOldRaw.size()];
                commMapAnon.put(parentComm.getID(), commsOldRaw.toArray(commNew));
            }
        }
    }




    /*** Methods used to manage collections added and removed during the application life cycle ***/
    /*Removes collection from the admin list when it is deleted
    * @param parentCommID
    * @param collectionID*/
    public static void removeCollectionFromAdminMapByID(int parentCommID, int collectionID) throws SQLException {
            removeColID(parentCommID,collectionID,true);
            removeFromCollectionAdminByColID(parentCommID);
    }
    /*Removes collection from non-admin list when it is deleted, becomes private or no longer has public items
    * Add collection to the admin list when it is created
    * Add collection and it parent communities to the non-admin list when collection becomes public
    * or when public items are added to it.
     * @param parentCommID
     * @param collectionID*/
    public static void removeCollectionFromAnonMapByID(int parentCommID, int collectionID) throws SQLException {
        removeColID(parentCommID,collectionID,false);
    }
    /*Add collection to admin list when collection is created
     *@param Collection*/
    public static void addCollectionToAdminMap(Collection col) throws SQLException {
        addCollection(col,true);
        buildAuthorizedColList(col);
        addCollectionToEmptyListID(col.getID());
        if(col.isPrivate()) {
            addCollectionToPrivateListID(col.getID());
        }
        if(col.isNYUOnly()) {
            addCollectionToNyuOnlyListID(col.getID());
        }
        if(col.isGallatin()) {
            addCollectionToGallatinOnlyListID(col.getID());
        }
    }
    /*Add collection to annon list when items are added to collection or non-empty collection is no longer private
     *@param Collection */
    public static void addCollectionToAnonMap(Collection col) throws SQLException {
        addCollection(col,false);
        removeFromCollectionAdminByColID(col.getID());
    }
    /*Remove collection from the array which is assosiated with it's parent community in admin or non-admin map using it's id
     * @param parentCommID
     * @param collectionID
     * @param admin*/
    private static void removeColID(int parentCommID, int collectionID, Boolean admin ) throws SQLException {
        if(admin) {
            if (colMapAdmin.containsKey(parentCommID) && colMapAdmin.get(parentCommID) != null) {
                Collection[] colsOld = colMapAdmin.get(parentCommID);
                LinkedList<Collection> colsOldRaw = new LinkedList(Arrays.asList(colsOld));
                for (Collection col: colsOldRaw) {
                    if(col.getID()==collectionID) {
                        colsOldRaw.remove(col);
                        if (colsOldRaw.size() > 0) {
                            Collection[] colsNew = new Collection[colsOldRaw.size()];
                            colMapAdmin.put(parentCommID, colsOldRaw.toArray(colsNew));
                        } else {
                            colMapAdmin.remove(parentCommID);
                        }
                    }
                }
            }
        } else {
            if (colMapAnon.containsKey(parentCommID) && colMapAnon.get(parentCommID) != null) {
                Collection[] colsOld = colMapAnon.get(parentCommID);
                LinkedList<Collection> colsOldRaw = new LinkedList(Arrays.asList(colsOld));
                for (Collection col: colsOldRaw) {
                    if(col.getID()==collectionID) {
                        colsOldRaw.remove(col);
                        if (colsOldRaw.size() > 0) {
                            Collection[] colsNew = new Collection[colsOldRaw.size()];
                            colMapAnon.put(parentCommID, colsOldRaw.toArray(colsNew));
                        } else {
                            colMapAnon.remove(parentCommID);
                            removeFromCommunityAdminByCommID(parentCommID);
                        }
                    }
                }
            }
        }
    }
    /*Add collection to the array which is assosiated with it's parent community in admin or non-admin map using it's id
     *@param Collection
     * @param admin */
    private static void addCollection(Collection col, Boolean admin) throws SQLException {
        Community[] parentComms =  col.getCommunities();
        if(parentComms!=null) {
            log.debug(" we are adding collection to map " + parentComms.length);

            for (Community parentComm : parentComms) {
                Collection[] colsChildren = parentComm.getCollections();
                if(colsChildren != null) {
                    LinkedList<Collection> colsChildrenRaw = new LinkedList(Arrays.asList(colsChildren));
                    if(colsChildrenRaw.contains(col)) {
                        int parentCommID = parentComm.getID();
                        if (admin) {
                            log.debug(" we are adding collection to admin map " + parentComms.length);
                            if (colMapAdmin.containsKey(parentCommID) && colMapAdmin.get(parentCommID) != null) {
                                Collection[] colsOld = colMapAdmin.get(parentCommID);

                                LinkedList<Collection> colsOldRaw = new LinkedList(Arrays.asList(colsOld));
                                if (!colsOldRaw.contains(col)) {
                                    colsOldRaw.add(col);
                                    Collection[] colsNew = new Collection[colsOldRaw.size()];
                                    colMapAdmin.put(parentCommID, colsOldRaw.toArray(colsNew));
                                }

                            } else {
                                Collection[] colsNew = {col};
                                colMapAdmin.put(parentComm.getID(), colsNew);
                            }
                        } else {
                            log.debug(" we are adding collection to non-admin map " + parentComms.length);
                            if (colMapAnon.containsKey(parentCommID) && colMapAnon.get(parentCommID) != null) {
                                Collection[] colsOld = colMapAnon.get(parentCommID);

                                LinkedList<Collection> colsOldRaw = new LinkedList(Arrays.asList(colsOld));
                                if (!colsOldRaw.contains(col)) {
                                    colsOldRaw.add(col);
                                    Collection[] colsNew = new Collection[colsOldRaw.size()];
                                    colMapAnon.put(parentCommID, colsOldRaw.toArray(colsNew));
                                }

                            } else {
                                Collection[] colsNew = {col};
                                colMapAnon.put(parentCommID, colsNew);
                                //if collection's parent community was not added to non-admin collection map,
                                // that parent community might not be added to the community map so we won't get to it
                                //To fix it we check that community parent community entry
                                Community nextParentComm = parentComm.getParentCommunity();
                                if (nextParentComm != null) {
                                    addParentComm(parentComm, admin);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    /*Update collection metadata in the map
    *@param Collection*/
    public static  void updateCollectionMetadata( Collection coL ) throws SQLException {

        if(coL.getParentObject()!=null) {
            int parentCommID = coL.getParentObject().getID();
            log.debug("updating collection for parent community id " + parentCommID);
                if (colMapAdmin.containsKey(parentCommID) && colMapAdmin.get(parentCommID) != null) {
                    Collection[] colsOld = colMapAdmin.get(parentCommID);
                    LinkedList<Collection> colsOldRaw = new LinkedList(Arrays.asList(colsOld));
                    for(Collection col:colsOldRaw ) {
                        if(col.getID()==coL.getID()) {
                                colsOldRaw.remove(col);
                        }
                    }
                    colsOldRaw.add(coL);
                    Collection[] colsNew = new Collection[colsOldRaw.size()];
                    log.debug("collection name "+coL.getName()+ " modified in admin list");
                    colMapAdmin.put(parentCommID, colsOldRaw.toArray(colsNew));

                }
                if (colMapAnon.containsKey(parentCommID) && colMapAnon.get(parentCommID) != null) {
                    Collection[] colsOld = colMapAdmin.get(parentCommID);
                    LinkedList<Collection> colsOldRaw = new LinkedList(Arrays.asList(colsOld));
                    for(Collection col:colsOldRaw ) {
                        if(col.getID()==coL.getID()) {
                            colsOldRaw.remove(col);
                        }
                    }
                    colsOldRaw.add(coL);
                    Collection[] colsNew = new Collection[colsOldRaw.size()];
                    log.debug("collection name "+coL.getName()+ " modified in non-admin list");
                    colMapAdmin.put(parentCommID, colsOldRaw.toArray(colsNew));
                }

        }

    }
    /*Remove collection id from the list of NYU Only collection
     *@param collectionID*/
    public static  void removeCollectionFromNyuOnlyListID(int collectionID)  {

        if( nyuOnly!=null) {
            nyuOnly.remove((Integer) collectionID);
        }

    }
    /*Remove collection id from the list of Gallatin Only collections
     *@param collectionID*/
    public static  void removeCollectionFromGallatinOnlyListID(int collectionID)  {

        if( gallatinOnly!=null) {
            gallatinOnly.remove((Integer) collectionID);
        }
    }
    /*Remove collection id from the list of private collections
     *@param collectionID*/
    public static  void removeCollectionFromPrivateListID(int collectionID)  {

        if( privateCollections!=null) {
            privateCollections.remove((Integer) collectionID);
        }

    }
    /*Remove collection id from the list of empty collection
     *@param collectionID*/
    public static  void removeCollectionFromEmptyListID(int collectionID)  {

        if( emptyCollections!=null) {
            emptyCollections.remove((Integer) collectionID);
        }

    }
    /*Add collection to NYU Only list
     *@param collectionID*/
    public static  void addCollectionToNyuOnlyListID(int collectionID)  {
            nyuOnly.addIfAbsent((Integer) collectionID);
    }
    /*Add collection id to the list of Gallatin Only collections
     *@param collectionID*/
    public static  void addCollectionToGallatinOnlyListID(int collectionID)  {
            gallatinOnly.addIfAbsent((Integer) collectionID);
    }
    /*Add collection id to the list of private collections
     *@param collectionID*/
    public static  void addCollectionToPrivateListID(int collectionID)  {
            privateCollections.addIfAbsent((Integer) collectionID);
    }
    /*Add collection id to the list of empty collection
     *@param collectionID*/
    public static  void addCollectionToEmptyListID(int collectionID)  {
            emptyCollections.addIfAbsent((Integer) collectionID);
    }
    /*Removes entries from authorized collection admin list when collection is removed
     *@param collectionID*/
    private static void removeFromCollectionAdminByColID(int collectionID){
        if( colAuthorizedUsers!=null) {
            Iterator iteratorAuthCollections = colAuthorizedUsers.iterator();
            while (iteratorAuthCollections.hasNext()) {
                AuthorizedCollectionUsers authCol = (AuthorizedCollectionUsers) iteratorAuthCollections.next();
                if (authCol.getCollectionID() == collectionID) {
                    log.debug("collection entry to remove " + authCol.getCollectionID());
                    colAuthorizedUsers.remove(authCol);
                }

            }
        }
    }


    /***Methods used to manage admin groups membership  during the application life cycle***/
    /* We will be handling here only cases when an eperson is added or removed to/from the group
     * Or when the whole group is removed. All other cases are handled on collection and community level
     * @param groupID */
    public static void DeleteGroup(int groupID){
        removeFromAdminByGroupID(groupID,true);
        removeFromAdminByGroupID(groupID,false);
    }
    /*Removes entries from authorized collection admin list when eperson is removed from group
     * @param groupID
     * @param epersonID*/
    public static void removeFromCollectionAdminByEpersonID( int groupID, int epersonID){
        removeFromAdminByEpersonID(groupID, epersonID, true);
    }
    /*Add entries to authorized collections admin list when new person is added to a group
     * @param groupID
     * @param epersonID
     * @param collectionID*/
    public static void addToCollectionAdminByEpersonID( int groupID, int epersonID, int collectionID){
        addToAdminByEpersonID(groupID,epersonID, collectionID,  true);
    }
    /*Removes entries from authorized communities  admin list when eperson is removed from group
     * @param groupID
     * @param epersonID*/
    public static void removeFromCommunityAdminByEpersonID( int groupID, int epersonID){
        removeFromAdminByEpersonID(groupID, epersonID, false);
    }
    /*Add entries to authorized communities  admin list when eperson is added to the group
     * @param groupID
     * @param epersonID
     * @param communityID*/
    public static void addToCommunityAdminByEpersonID( int groupID, int epersonID, int communityID){
        addToAdminByEpersonID(groupID,epersonID, communityID,  false);
    }
    /*Do actual removal from communiuty or collection admin list for user
     * @param groupID
     * @param changeCol
     */
    private static void removeFromAdminByGroupID(int groupID, Boolean changeCol){
        if( changeCol&&colAuthorizedUsers!=null) {
            Iterator iteratorAuthCollections = colAuthorizedUsers.iterator();
            while (iteratorAuthCollections.hasNext()) {
                AuthorizedCollectionUsers authCol = (AuthorizedCollectionUsers) iteratorAuthCollections.next();
                if (authCol.getGroupID() == groupID) {
                    log.debug("group entry to remove " + authCol.getGroupID());
                    colAuthorizedUsers.remove(authCol);
                }

            }
        }
        if( !changeCol&&commAuthorizedUsers!=null) {
            Iterator iteratorAuthCommunities = commAuthorizedUsers.iterator();
            while (iteratorAuthCommunities.hasNext()) {
                AuthorizedCommunityUsers authComm = (AuthorizedCommunityUsers) iteratorAuthCommunities.next();
                if (authComm.getGroupID() == groupID) {
                    log.debug("group entry to remove " + authComm.getGroupID());
                    commAuthorizedUsers.remove(authComm);
                }

            }
        }
    }
    /*Do actula removal from community or collection admin list for specific person from the group
    * @param groupID
    * @param epersonID
    * @param changeCol*/
    private static void removeFromAdminByEpersonID(int groupID,int epersonID, Boolean changeCol){
        if( changeCol&&colAuthorizedUsers!=null) {
            Iterator iteratorAuthCollections = colAuthorizedUsers.iterator();
            while (iteratorAuthCollections.hasNext()) {
                AuthorizedCollectionUsers authCol = (AuthorizedCollectionUsers) iteratorAuthCollections.next();
                if (authCol.getGroupID() == groupID && authCol.getEpersonID()==epersonID) {
                    log.debug("group entry to remove " + authCol.getGroupID()+" eperson to remove "+authCol.getEpersonID());
                    colAuthorizedUsers.remove(authCol);
                }

            }
        }
        if( !changeCol&&commAuthorizedUsers!=null) {
            Iterator iteratorAuthCommunities = commAuthorizedUsers.iterator();
            while (iteratorAuthCommunities.hasNext()) {
                AuthorizedCommunityUsers authComm = (AuthorizedCommunityUsers) iteratorAuthCommunities.next();
                if (authComm.getGroupID() == groupID && authComm.getEpersonID()==epersonID) {
                    log.debug("group entry to remove " + authComm.getGroupID()+" eperson to remove "+authComm.getEpersonID());
                    commAuthorizedUsers.remove(authComm);
                }

            }
        }
    }
    /*Do actual addition to  community or collection admin list for specific person from the group
     * @param groupID
     * @param epersonID
     * @param objectID
     * @param changeCol*/
    private static void addToAdminByEpersonID(int groupID,int epersonID, int objectID, Boolean changeCol) {
       if(changeCol) {
           colAuthorizedUsers.add(new AuthorizedCollectionUsers(epersonID,groupID,objectID));
       } else {
           commAuthorizedUsers.add(new AuthorizedCommunityUsers(epersonID,groupID,objectID));
       }
    }

    /*Modify maps and lists when collection policy is modified. That method is called by admin servlet AuthorizeAdminServlet
     * @param Collection  */
    public static void checkCollection(Collection collection) throws SQLException {
        int collectionID=collection.getID();
        if(collection.isPrivate()) {
            if(privateCollections==null || !privateCollections.contains(collectionID)) {
                addCollectionToPrivateListID(collectionID);
            }
        } else {
            if(privateCollections.contains(collectionID)) {
                removeCollectionFromPrivateListID(collectionID);
                if(!emptyCollections.contains(collectionID)) {
                    addCollectionToAnonMap(collection);
                }
            }
        }
        if(collection.isNYUOnly()) {
            if(nyuOnly==null || !nyuOnly.contains(collectionID)) {
                addCollectionToNyuOnlyListID(collectionID);
            }
        } else {
            if(nyuOnly.contains(collectionID)) {
                removeCollectionFromNyuOnlyListID(collectionID);
            }
        }
        if(collection.isGallatin()) {
            if(gallatinOnly==null || !gallatinOnly.contains(collectionID)) {
                addCollectionToGallatinOnlyListID(collectionID);
            }
        } else {
            if(gallatinOnly.contains(collectionID)) {
                removeCollectionFromGallatinOnlyListID(collectionID);
            }
        }
    }

}

