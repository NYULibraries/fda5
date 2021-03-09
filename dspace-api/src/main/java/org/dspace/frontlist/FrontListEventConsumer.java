package org.dspace.frontlist;

import org.apache.log4j.Logger;

import java.util.*;

import org.dspace.authorize.AuthorizeManager;
import org.dspace.authorize.ResourcePolicy;
import org.dspace.content.DSpaceObject;
import org.dspace.core.Constants;
import org.dspace.content.Collection;
import org.dspace.core.Context;
import org.dspace.event.Consumer;
import org.dspace.event.Event;
import org.dspace.app.util.ListUserCommunities;
import org.dspace.content.Community;
import org.dspace.eperson.EPerson;
import org.dspace.eperson.Group;


public class FrontListEventConsumer implements Consumer {
        /**
         * log4j logger
         */
        private static Logger log = Logger.getLogger(FrontListEventConsumer.class);



        public void initialize() throws Exception {

        }

        /**
         * Consume a content event -- just build the sets of objects to add (new) to
         * the index, update, and delete.
         *
         * @param ctx   DSpace context
         * @param event Content event
         */
        public void consume(Context ctx, Event event) throws Exception {

                int  st= event.getSubjectType();
                int et= event.getEventType();

                if (st != Constants.COLLECTION && st!= Constants.GROUP && st!= Constants.COMMUNITY&& st!= Constants.SITE ) {
                        log
                                .warn("FrontListConsumer should not have been given this kind of Subject in an event, skipping: "
                                        + event.toString());
                        return;
                }
                if(st==Constants.COLLECTION ) {
                        Collection s = (Collection) event.getSubject(ctx);
                        if(s!=null) {
                                if (et == Event.REMOVE) {
                                        if (s.countItems() == 0) {
                                                log.warn(" processing removing item");
                                                processRemoveItem(s);

                                        }
                                }
                                if (et == Event.ADD) {
                                        if (event.getObject(ctx) != null && event.getObjectType() == Constants.ITEM) {
                                                if (ListUserCommunities.emptyCollections != null &&
                                                        ListUserCommunities.emptyCollections.contains(s)) {
                                                        log.warn(" processing adding item");
                                                        processAddItem(s);
                                                }


                                        }
                                }
                                if (et == Event.MODIFY_METADATA) {
                                        log.warn(" processing adding collection");
                                        processUpdateCollection(s);
                                }

                        }

                }


                if(st==Constants.COMMUNITY ) {
                        if(event.getSubject(ctx)!=null) {
                                Community s = (Community) event.getSubject(ctx);
                                    if(event.getObjectID()!=-1) {
                                            int objectID = event.getObjectID();
                                            if (event.getObjectType() == Constants.COLLECTION) {

                                                   if (et == Event.ADD) {
                                                            if (event.getObject(ctx) != null) {
                                                                    log.warn(" processing adding collection");
                                                                    Collection o = (Collection) event.getObject(ctx);
                                                                    processAddCollection(s, o);
                                                            }
                                                    }
                                                    if (et == Event.REMOVE) {
                                                            log.warn(" processing removing collection");
                                                            processRemoveCollection(s, objectID);

                                                    }
                                            }
                                            if (event.getObjectType() == Constants.COMMUNITY) {

                                                    if (et == Event.REMOVE) {
                                                            log.warn(" processing removing community");
                                                            processRemoveCommunity(s, objectID);

                                                    }
                                            }
                                    } else {
                                            if (et == Event.MODIFY_METADATA) {
                                                    log.warn(" processing adding/updating  community");
                                                    processUpdateCommunity(s);
                                            }
                                            if (et == Event.CREATE) {
                                                    log.warn(" processing adding community");
                                                    processAddCommunity(s);
                                            }


                                    }
                        } else {
                                if (et == Event.DELETE) {
                                        log.warn(" processing deleteing community");
                                        processDeleteCommunity(event.getSubjectID());
                                }
                        }
                }

                if(st==Constants.GROUP ) {
                        if(event.getObject(ctx)!=null && event.getObjectType()==Constants.COLLECTION) {
                                processModifyGroup(ctx, (EPerson) event.getObject(ctx), (Group) event.getSubject(ctx), et);
                        }
                }


        }



        /**
         * Process sets of objects to add, update, and delete in index. Correct for
         * interactions between the sets -- e.g. objects which were deleted do not\
         *
         * need to be added or updated, new objects don't also need an update, etc.
         */
        public void end(Context ctx) throws Exception {


        }

        public void finish(Context ctx) throws Exception {
            // No-op

        }

        private void processModifyGroup( Context context, EPerson eperson, Group group, int eventType ) throws java.sql.SQLException {
                List<ResourcePolicy> rps= AuthorizeManager.getPoliciesForGroup(context, group);
                for (ResourcePolicy rp:rps) {
                        int resourceID = rp.getResourceID();
                        int resourceType = rp.getResourceType();

                        if(resourceType== Constants.COLLECTION) {
                                Collection  col =(Collection) DSpaceObject.find(context, resourceType, resourceID );
                                if((ListUserCommunities.privateCollections!=null && ListUserCommunities.privateCollections.contains(col) )||
                                        (ListUserCommunities.emptyCollections!=null && ListUserCommunities.emptyCollections.contains(col)) ) {

                                        if(eventType==Event.ADD) {
                                                ListUserCommunities.addAuthorizedUser(col, eperson);
                                        }
                                        if(eventType==Event.REMOVE) {
                                                ListUserCommunities.removeAuthorizedUser(col, eperson);
                                        }
                                }
                        }
                        if(resourceType== Constants.COMMUNITY) {
                                Community  com =(Community) DSpaceObject.find(context, resourceType, resourceID );
                                if(com.getAllCollections().length==0) {

                                        if(eventType==Event.ADD) {
                                                ListUserCommunities.addAuthorizedUser(com, eperson);
                                        }
                                        if(eventType==Event.REMOVE) {
                                                ListUserCommunities.removeAuthorizedUser(com, eperson);
                                        }
                                }
                        }
                        if(resourceType== Constants.GROUP) {
                                Group  parentGroup =(Group) DSpaceObject.find(context, resourceType, resourceID );
                                processModifyGroup(context, eperson, parentGroup, eventType);
                        }
                }
        }

        private void processAddItem( Collection col ) throws java.sql.SQLException {

                        if(ListUserCommunities.emptyCollections!=null
                                && ListUserCommunities.emptyCollections.contains(col)) {
                                ListUserCommunities.removeCollectionFromEmptyList(col);
                                if(!col.isPrivate()) {
                                        ListUserCommunities.removeUsersFromAuthorizedColList(col);
                                        ListUserCommunities.addCollectionToAnnonList(col);
                                }

                        }



        }

        private void processRemoveItem( Collection col ) throws java.sql.SQLException {
                               ListUserCommunities.addCollectionToEmptyList(col);
                                if( !ListUserCommunities.privateCollections.contains(col)) {
                                        ListUserCommunities.removeCollectionFromAnnonList(col);
                                }


        }

        private void processAddCollection( Community comm, Collection col ) throws java.sql.SQLException {

                log.warn("We continue adding collection");
                ListUserCommunities.addCollectionToEmptyList(col);
                log.warn("We adding collection to Admin list");
                ListUserCommunities.addCollectionToAdminListID(comm, col);
                ListUserCommunities.addUsersToAuthorizedColList(col);

                if(col.isPrivate()) {
                                ListUserCommunities.addCollectionToPrivateList(col);
                }
                if(col.isNYUOnly()) {
                                ListUserCommunities.addCollectionToNYUOnlyList(col);
                }
                if(col.isGallatin()) {
                                ListUserCommunities.addCollectionToGallatinOnlyList(col);
                }


        }

        private void processAddCommunity( Community comm ) throws java.sql.SQLException {

                ListUserCommunities.addCommunityToAdminList(comm);
                ListUserCommunities.addUsersToAuthorizedComList(comm);


        }

        private void processRemoveCollection( Community comm, int collectionID ) throws java.sql.SQLException {

                ListUserCommunities.removeCollectionFromAnnonListID(comm,collectionID);
                ListUserCommunities.removeCollectionFromAdminListID(comm,collectionID);
                ListUserCommunities.removeCollectionFromEmptyListID(collectionID);
                ListUserCommunities.removeCollectionFromPrivateListID(collectionID);
                ListUserCommunities.removeCollectionFromNYUOnlyListID(collectionID);
                ListUserCommunities.removeCollectionFromGallatinOnlyListID(collectionID);

        }

        private void processRemoveCommunity( Community parentComm, int communityID ) throws java.sql.SQLException {

                ListUserCommunities.removeCommunityFromAdminListID(parentComm,communityID);
                ListUserCommunities.removeCommunityFromAnnonListID(parentComm,communityID);

        }

        private void processDeleteCommunity(  int communityID ) throws java.sql.SQLException {

                ListUserCommunities.removeChildrenCommunityFromAdminListID(communityID);
                ListUserCommunities.removeChildrenCommunityFromAnnonListID(communityID);

        }

        private void processCreateCommunity(  Community comm ) throws java.sql.SQLException {

                ListUserCommunities.addCommunityToAdminListID(comm.getID());
                ListUserCommunities.addUsersToAuthorizedComList(comm);

        }

        private void processUpdateCollection(Collection col) throws java.sql.SQLException {
                ListUserCommunities.updateCollectionMetadata(col, true);
                ListUserCommunities.updateCollectionMetadata(col, false);
        }

        private void processUpdateCommunity(Community comm) throws java.sql.SQLException {
                ListUserCommunities.updateCommunityMetadata(comm, true);
                ListUserCommunities.updateCommunityMetadata(comm, false);

        }
}
