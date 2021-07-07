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
import java.util.Iterator;

import org.apache.log4j.Logger;

import org.dspace.content.Community;
import org.dspace.content.Collection;
import org.dspace.core.Context;

/**
 * This class makes calculations to display list of communities tailored for a specific user
 * those calculations are used by ListCommunitiesSiteProcessor, which in turn pass those maps to jsp pages
 * @author Kate Pechekhonova
 *
 */
public class ListCommunities {

    // This will map communityIDs to arrays of collections for specific user
    private HashMap<Integer, Collection[]> colMap=new HashMap<Integer, Collection[]>();

    // This will map communityIDs to arrays of sub-communities for specific user
    private Map<Integer, Community[]> commMap=new HashMap<Integer, Community[]>();;


    /**
     * log4j category
     */
    private static Logger log = Logger.getLogger(ListUserCommunities.class);

    //We start with generic list to which we will add private and empty collections and comunities for which the user has admin/submitter access
    public ListCommunities() {

        colMap.putAll(ListUserCommunities.colMapAnon);
        commMap.putAll(ListUserCommunities.commMapAnon);

    }

    //Returns map with all communities->subcommunities available to the user
    public Map getCommunitiesMap() {
        return commMap;
    }

    //Returns map with all communities->collections available to the user
    public Map getCollectionsMap() {
        return colMap;
    }


    //Build  full community/collection list for the user and updates commMap and colMap attributes
    // It will be displayed on home page and list-communities.jsp page for the user
   public void BuildUserCommunitiesList(Context context) throws java.sql.SQLException {

        int userID = context.getCurrentUser().getID();
        log.debug(" size of generic collection Map:"+ListUserCommunities.colMapAnon.size());
        log.debug(" size of generic community Map:"+ListUserCommunities.commMapAnon.size());

        ArrayList userComm = ListUserCommunities.getAuthorizedCommunities(userID);
        ArrayList userCol = ListUserCommunities.getAuthorizedCollections(userID);

        // We only add communities which have collections that the user can see
        if(userCol!= null ) {
            for (Object colID:userCol) {
                log.debug("collection we will add "+userCol.size());
                Collection coL = Collection.find(context,(Integer) colID);
                if(coL!=null) {
                    addUserCol(coL);
                }
            }
        }
        // We only add communities which have sub-communities that the user can see
        if(userComm!= null ) {
            for (Object comID:userComm) {
                log.debug("community we will add "+userComm.size());
                Community comm = Community.find(context,(Integer) comID);
                if(comm != null) {
                    log.debug("community to add "+comm.getName());
                    addUserComm(comm);
                }
            }
        }
        log.debug(" size of tailored collection Map:"+colMap.size());
        log.debug(" size of tailored community Map:"+commMap.size());
    }

    //if community is visible to the user we also need to see it's parents and children community/collection in the community tree
    private void addUserComm(Community com ) throws java.sql.SQLException {
            addParentComm(com);
            addChildrenComm(com);
    }

    //If community is visible to the user then we also need to add it's parent community to the community tree
    //so we can get access to it.
    private void addParentComm( Community com ) throws java.sql.SQLException {
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

    //if community is visible to the user then it's collections and sub-communities are also visible to the user and need to be added to the tree
    private void addChildrenComm( Community com ) throws java.sql.SQLException {

        Collection[] colls = com.getCollections();
        if (colls.length > 0) {
            colMap.put(com.getID(), colls);
        }
        Community[] comms = com.getSubcommunities();
        if (comms.length > 0) {
            commMap.put(com.getID(), comms);
            for(Community subcomm:comms) {
                addChildrenComm(subcomm);
            }
        } else {
            commMap.put(com.getID(), null);
        }
    }

    //If collection is visible to the user we need to add it to the tree as well as all it's parent community
    private void addUserCol(Collection col ) throws java.sql.SQLException {
        log.debug("collection id"+col.getID());
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

}