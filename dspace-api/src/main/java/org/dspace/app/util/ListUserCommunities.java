/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 * <p>
 * http://www.dspace.org/license/
 */
package org.dspace.app.util;


import java.sql.SQLException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Map;
import java.util.List;

import org.apache.log4j.Logger;

import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.Community;
import org.dspace.content.Collection;
import org.dspace.core.Context;
import  org.dspace.eperson.EPerson;
import  org.dspace.eperson.Group;

/**
 * This class generates list of collections and c ommunities which will be listed on home page and on community pages
 * Anonymous users can only see - public, NYU only and school specific (Gallatin) collection which are not empty
 * Collection, community and site admins can see empty and private collections which ther administrate. Also submitters
 * can see empty collections to which they can add items.
 * We make all initial calculations when jspui applications starts and then do updates when changes are made, e.g.
 * when items are added to empty collection, when new admins are added to private collections or when collection permissions
 * are modified.
 *
 * @author Kate Pechekhonova
 *
 */
public class ListUserCommunities {


    // This contains list of NYU only collections
    public static ArrayList<Collection> nyuOnly;

    // This contains list of Gallatin only collectiuons
    public static ArrayList<Collection> gallatinOnly;

    // This contains list of empty collections
    public static ArrayList<Collection> emptyCollections;

    // This contains list of private collections
    public static ArrayList<Collection> privateCollections;

    // This will map collectionIDs to arrays of collections
    public static Map<Integer, Collection[]> colMapAnon;

    // This will map communityIDs to arrays of sub-communities
    public static Map<Integer, Community[]> commMapAnon;

    // This will map collectionIDs to arrays of collections
    public static Map<Integer, Collection[]> colMapAdmin;

    // This will map communityIDs to arrays of sub-communities
    public static Map<Integer, Community[]> commMapAdmin;

    // This will map collectionIDs to arrays of collections
    public static Map<Integer, Collection[]> colAuthorizedUsers;

    // This will map communityIDs to arrays of sub-communities
    public static Map<Integer, Community[]> commAuthorizedUsers;


    private static final Object staticLock = new Object();

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

    //generates maps for anon user, for site admins and other
    public static synchronized void ListAnonUserCommunities() throws java.sql.SQLException {

        Context context = new Context();

        if( colMapAnon==null && commMapAnon==null) {

            colMapAnon = new HashMap<Integer, Collection[]>();
            commMapAnon = new HashMap<Integer, Community[]>();
            colMapAdmin = new HashMap<Integer, Collection[]>();
            commMapAdmin = new HashMap<Integer, Community[]>();
            colAuthorizedUsers = new HashMap<Integer, Collection[]>();
            commAuthorizedUsers = new HashMap<Integer, Community[]>();
            nyuOnly = new ArrayList<Collection>();
            gallatinOnly = new ArrayList<Collection>();
            privateCollections = new ArrayList<Collection>();
            emptyCollections = new ArrayList<Collection>();


            Community[] communities = Community.findAll(context);

            if(communities!=null) {
                //user only can see non-empty, not private collections
                for (int com = 0; com < communities.length; com++) {
                    buildCollection(communities[com], context);
                }
            }

            Community[] communitiesAval = Community.findAllTop(context);

            if(communitiesAval!=null) {
                // we only include communities which has collections that the user can see
                for (int com = 0; com < communitiesAval.length; com++) {
                    buildCommunity(communitiesAval[com], context);
                }
            }
        }

    }

    private static void buildCollection(Community c, Context context) throws SQLException {
        Integer comID = c.getID();

        Collection[] colls = c.getCollections();

        colMapAdmin.put(comID, colls);
        log.error("community: "+c.getName()+" size: "+ colMapAdmin.get(comID).length);

        if (colls.length > 0) {
            log.error("length"+colls.length);
            ArrayList<Collection> availableCol = new ArrayList<Collection>();


            for (int i = 0; i < colls.length; i++) {

                int countItems = colls[i].countItems();
                if (colls[i].isPublic()) {
                    if(countItems>0) {
                        availableCol.add(colls[i]);
                    } else {
                        emptyCollections.add(colls[i]);
                    }
                } else {
                    if (colls[i].isNYUOnly()) {
                        if(countItems>0) {
                            availableCol.add(colls[i]);
                        } else {
                            emptyCollections.add(colls[i]);
                        }
                        nyuOnly.add(colls[i]);

                    } else {

                        if (colls[i].isGallatin()) {
                            if(countItems>0) {
                                availableCol.add(colls[i]);
                            } else {
                                emptyCollections.add(colls[i]);
                            }
                            gallatinOnly.add(colls[i]);
                        }
                    }
                }

                if (!availableCol.contains(colls[i])) {
                    log.error("or here at admins " + colls[i].getName());
                    ArrayList<EPerson> epersons = getAuthirizedCollectionUsers(colls[i]);
                    log.error("admins: " + epersons.size());
                    for (EPerson eperson : epersons) {
                        log.error("eperson: " + eperson.getName());
                        if (colAuthorizedUsers.containsKey(eperson.getID())) {
                            Collection[] colsOld = colAuthorizedUsers.get(eperson.getID());
                            if (colsOld != null) {
                                List<Collection> colsOldRaw = (List<Collection>) Arrays.asList(colsOld);
                                if (!colsOldRaw.contains(colls[i])) {
                                    ArrayList<Collection> colsNewRaw = new ArrayList<Collection>();
                                    colsNewRaw.add(colls[i]);
                                    for (Object colsold : colsOldRaw) {
                                        colsNewRaw.add((Collection) colsold);
                                    }

                                    Collection[] colsNew = new Collection[colsNewRaw.size()];
                                    colAuthorizedUsers.put(eperson.getID(), colsNewRaw.toArray(colsNew));
                                    log.error("added to map: " + colAuthorizedUsers.get(eperson.getID()).length);
                                }
                            }
                        } else {
                            Collection[] colsNew = {colls[i]};
                            colAuthorizedUsers.put(eperson.getID(), colsNew);
                        }
                    }

                    if(colls[i].isPrivate()) {
                        privateCollections.add(colls[i]);
                    }
                     if(countItems==0) {
                        emptyCollections.add(colls[i]);
                     }

                }
            }
            if (availableCol.size() > 0) {
                Collection[] availableColArray = new Collection[availableCol.size()];
                colMapAnon.put(comID, availableCol.toArray(availableColArray));
            }
        }

    }


    private static void buildCommunity(Community c, Context context) throws SQLException {
        Integer comID = c.getID();

        Community[] comms = c.getSubcommunities();

        commMapAdmin.put(comID, comms);

        if (comms.length > 0) {
            ArrayList<Community> availableComm = new ArrayList<Community>();

            for (int i = 0; i < comms.length; i++) {

                buildCommunity(comms[i], context);

                if (colMapAnon.containsKey(comms[i].getID())
                        || commMapAnon.containsKey(comms[i].getID())) {
                    availableComm.add(comms[i]);
                } else {
                    ArrayList<EPerson> epersons = getAuthirizedCommunityUsers(comms[i]);
                    for(EPerson eperson:epersons) {
                        if(commAuthorizedUsers.containsKey(eperson.getID())) {
                            Community[] commsOld = commAuthorizedUsers.get(eperson.getID());
                            if(commsOld!=null) {
                                List<Community> commsOldRaw = (List<Community>) Arrays.asList(commsOld);
                                if (!commsOldRaw.contains(comms[i])) {
                                    ArrayList<Community> commsNewRaw = new ArrayList<Community>();
                                    commsNewRaw.add(comms[i]);
                                    for (Object commsold : commsOldRaw) {
                                        commsNewRaw.add((Community) commsold);
                                    }

                                    Community[] commsNew = new Community[commsNewRaw.size()];
                                    commAuthorizedUsers.put(eperson.getID(), commsNewRaw.toArray(commsNew));
                                }
                            }
                        } else {
                            Community[] commsNew = {comms[i]};
                            commAuthorizedUsers.put(eperson.getID(), commsNew );
                        }
                    }
                }
            }
            if (availableComm.size() > 0) {
                Community[] availableCommArray = new Community[availableComm.size()];
                commMapAnon.put(comID, availableComm.toArray(availableCommArray));
            }
        }
    }



    private static ArrayList<EPerson> getAuthirizedCollectionUsers(Collection col) throws SQLException {

            ArrayList<EPerson> epersons= new ArrayList<EPerson>();
            ArrayList<EPerson> allusers= new ArrayList<EPerson>();

            Group admins = col.getAdministrators();
            if(admins!=null) {
              allusers =  getAllGroupUsers(admins);
                if(allusers!=null) {
                    epersons.addAll(allusers);
                }
            }

        Group submitters = col.getSubmitters();
        if(submitters!=null) {
            allusers =  getAllGroupUsers(submitters);
            if(allusers!=null) {
                epersons.addAll(allusers);
            }
        }
        return epersons;
    }

    private static ArrayList<EPerson> getAuthirizedCommunityUsers(Community com) throws SQLException {

        ArrayList<EPerson> epersons= new ArrayList<EPerson>();
        ArrayList<EPerson> allusers= new ArrayList<EPerson>();

        Group admins = com.getAdministrators();
        if(admins!=null) {
            allusers =  getAllGroupUsers(admins);
            if(allusers!=null) {
                epersons.addAll(allusers);
            }
        }
        return epersons;
    }

    private static ArrayList<EPerson> getAllGroupUsers(Group g) {

        ArrayList<EPerson> epersons= new ArrayList<EPerson>();

        for(EPerson eperson:g.getMembers()) {
           epersons.add(eperson);
        }
        for(Group ag:g.getMemberGroups()) {
            for(EPerson geperson:ag.getMembers()) {
                epersons.add(geperson);
            }

        }
        return epersons;
    }


}

