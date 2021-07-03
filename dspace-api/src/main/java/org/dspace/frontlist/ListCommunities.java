package org.dspace.frontlist;

/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 * <p>
 * http://www.dspace.org/license/
 */

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import org.dspace.content.Community;
import org.dspace.content.Collection;
import org.dspace.core.Context;
import org.dspace.app.util.ListUserCommunities;

/**
 * This class generates list of all collections and communities which are not empty or where the user is administrator or submitter
 *
 * @author Kate Pechekhonova
 *
 */
public class ListCommunities {

    // This will map communityIDs to arrays of collections
    private HashMap<Integer, Collection[]> colMap=new HashMap<Integer, Collection[]>();

    // This will map communityIDs to arrays of sub-communities
    private Map<Integer, Community[]> commMap=new HashMap<Integer, Community[]>();;

    /**
     * Our context
     */
    protected Context ourContext;


    /**
     * log4j category
     */
    private static Logger log = Logger.getLogger(org.dspace.app.util.ListUserCommunities.class);

    //used for full community list on home page and list-communities.jsp page
    public ListCommunities() {

        colMap.putAll(ListUserCommunities.colMapAnon);
        commMap.putAll(ListUserCommunities.commMapAnon);

    }

    public Map getCommunitiesMap() {
        return commMap;
    }

    public Map getCollectionsMap() {
        return colMap;
    }


    //used for full community list on home page and list-communities.jsp page for a specific loged in user
   public void ListUserCommunities(Context context) throws java.sql.SQLException {

        ourContext = context;
        int userID = context.getCurrentUser().getID();


        log.error(" global:"+ListUserCommunities.colMapAnon.size());

        Community[] userComm = ListUserCommunities.commAuthorizedUsers.get(userID);
        Collection[] userCol = ListUserCommunities.colAuthorizedUsers.get(userID);

        // we only include communities which has collections that the user can see
        if(userCol!= null ) {
            for (int col = 0; col < userCol.length; col++) {
                log.warn("collection we will add"+userCol[col].getName());
                Collection coL = Collection.find(ourContext, userComm[col].getID());
                if(coL!=null) {
                    addUserCol(coL);
                }
            }
        }
        if(userComm!= null ) {
            for (int com = 0; com < userComm.length; com++) {
                Community comm = Community.find(ourContext, userComm[com].getID());
                if(comm != null) {
                    addUserComm(comm);
                }
            }
        }
        log.error(" local:"+colMap);

    }

    private void addUserComm(Community com ) throws java.sql.SQLException {
            addParentComm(com);
            addChildrenComm(com);
    }

    private void addChildrenComm( Community com ) throws java.sql.SQLException {

        Collection[] colls = com.getCollections();
        if (colls.length > 0) {
            colMap.put(com.getID(), colls);
        }
        Community[] comms = com.getSubcommunities();
        if (comms.length > 0) {
            commMap.put(com.getID(), comms);
            for(Community subcomm:comms) {
                addChildrenComm(  subcomm);
            }
        }
    }

    private void addUserCol(Collection col ) throws java.sql.SQLException {
        log.warn("col id"+col.getID());
        Community[] parentComms =  col.getCommunities();
        for (Community parentComm:parentComms) {
            //need to check that it is "primary" parent collection
            Collection[] colsAll = parentComm.getCollections();
            List<Collection> colsAllRaw =  Arrays.asList(colsAll);
            if (colsAllRaw.contains(col)) {
                if (colMap.containsKey(parentComm.getID()) && colMap.get(parentComm.getID()) != null) {
                    Collection[] colsOld = colMap.get(parentComm.getID());

                    List<Collection> colsOldRaw =  Arrays.asList(colsOld);
                    if (!colsOldRaw.contains(col)) {
                        ArrayList<Collection> colsNewRaw = new ArrayList<Collection>();
                        colsNewRaw.add(col);
                        for (Object colsold : colsOldRaw) {
                            colsNewRaw.add((Collection) colsold);
                        }

                        Collection[] colsNew = new Collection[colsNewRaw.size()];
                        colMap.put(parentComm.getID(), colsNewRaw.toArray(colsNew));
                    }

                } else {
                    Collection[] colsNew = {col};
                    colMap.put(parentComm.getID(), colsNew);
                }

                Community nextParentComm = parentComm.getParentCommunity();
                if (nextParentComm != null) {
                    addParentComm( parentComm);
                }
            }
        }

    }

    private void addParentComm( Community com ) throws java.sql.SQLException {
        log.warn("community add parent:"+com.getName());
        log.warn("community add parent:"+com.getID());
        Community parentComm = com.getParentCommunity();
        if(parentComm!=null) {
            if ( commMap.containsKey(parentComm.getID()) && commMap.get(parentComm.getID())!=null) {
                Community[] commOld = commMap.get(parentComm.getID());
                List<Community> commOldRaw =  Arrays.asList(commOld);
                if (!commOldRaw.contains(com)) {
                    ArrayList<Community> commNewRaw = new ArrayList<Community>();
                    commNewRaw.add(com);
                    for (Object commold : commOldRaw) {
                        commNewRaw.add((Community) commold);
                    }

                    Community[] commNew = new Community[commNewRaw.size()];
                    commMap.put(parentComm.getID(), commNewRaw.toArray(commNew));
                }
            } else {
                Community[] commNew = {com};
                commMap.put(parentComm.getID(), commNew);
            }

            Community nextParentComm = parentComm.getParentCommunity();
            if (nextParentComm != null) {
                addParentComm(parentComm);
            }
        }
    }




}

