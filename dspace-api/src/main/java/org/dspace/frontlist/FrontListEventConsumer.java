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
import org.dspace.content.Community;
import org.dspace.content.Item;
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
         * We do not want to show  private and empty collections to non-admin users.
         * Only those users who can administrate private or empty collection or can submitte to those collections, will see them.
         * It has proved to be too resource intensive to calculate on the fly which communities and collection to show to a specific user
         * To reduce the amount of calculations we do most calculations on the application startup
         * On the start up we initialize 4 static ConcurrentHashMaps objects:
         * Map of communities and collections for site admins colMapAdmin,comMapAdmin
         * Map of communities and collections for all non-admin users colMapAnon,comMapAnon
         * Each entry in maps for collections has community id as a key and array of those community collections as a value
         * < Parent Community ID, [array of collections]>
         * Each entry in maps for communities has parent community id as a key and array of those community subcommunties as a value
         * < Parent Community ID, [array of subcommunties]>
         * As we have a limited number of  users who can get access to private ans empty collections,
         * for those users we will add communities and collections on the fly.
         * On the application start up we pre-calculate the list of those users and keep them in 2 static CopyOnWriteArrayLists (we use this type to
         * avoid concurrency issues) - colAuthorizedUsers and commAuthorizedUsers.
         * Each item in colAuthorizedUsers is an object of custom type AuthorizedCollectionUsers. It keep the triple <eperson ID, group ID, collection ID>
         * Each item in commAuthorizedUsers is an object of custom type AuthorizedCollectionUsers. It keep the triple <eperson ID, group ID, community ID>
         * Also we pre-calculate 4 objects of CopyOnWriteArrayLists - nyuOnly, gallatinOnly, emptyCollections, privateCollections
         * All those objects are used By Classes
         * ListCommunitiesSiteProcessor to generate site home page (objects will be passed to home.jsp as attributes)
         * ListCommunitiescomminityProcessor to generate community home page (objects will be passed to community-home.jsp as attributes)
         * ComminityListServlet to generate communities and collection lists (objects will be passed to community-list.jsp as attributes)
         * As we make all initial calculations when the application starts we need to update the objects  when the following changes are made:
         * when items are added to empty collection,
         * when all items are removed from collection,
         * when new admins or submitters are added or removed for private or empty collections,
         * when collection permissions are modified,
         * when collections and communities are added or removed
         * when collection and community metadata is modified
         * We use this class to consume the information of the event listed above and trigger the appropriate calculations.
         * More information about Dspace event processing system here - https://wiki.lyrasis.org/display/DSPACE/EventSystemPrototype
         * @param ctx   DSpace context
         * @param event Content event
         */
        public void consume(Context ctx, Event event) throws Exception {

                int  st= event.getSubjectType();
                int et= event.getEventType();

                //check that we only get  events we need
                if (st != Constants.COLLECTION && st!= Constants.GROUP && st!= Constants.COMMUNITY
                        && st!= Constants.SITE && st != Constants.ITEM ) {
                        log
                                .warn("FrontListConsumer should not have been given this kind of Subject in an event, skipping: "
                                        + event.toString());
                        return;
                }
                //remove top level community
                if(st==Constants.SITE ) {
                        if(event.getObjectID()!=-1 && et == Event.REMOVE) {
                                int objectID = event.getObjectID();
                                log.warn(" processing removing community");
                                processRemoveCommunityID(objectID);
                        }

                }
                //community related events, e.g. when community is a subject and some action is performed over community element, e.g. object
                //any event has subject and action but some like "COMMUNITY DELETE " might not have object
                if(st==Constants.COMMUNITY ) {
                        if(event.getSubject(ctx)!=null) {
                                Community s = (Community) event.getSubject(ctx);
                                if(event.getObjectID()!=-1) {
                                        int objectID = event.getObjectID();
                                        //add or remove collection to the community, the event is issued AFTER collection is added/removed to/from the community
                                        if (event.getObjectType() == Constants.COLLECTION) {

                                                if (et == Event.ADD) {
                                                        if (event.getObject(ctx) != null) {
                                                                log.debug(" processing adding collection");
                                                                Collection o = (Collection) event.getObject(ctx);
                                                                processAddCollection(s, o);
                                                        }
                                                }
                                                if (et == Event.REMOVE ) {
                                                        log.warn(" processing removing collection");
                                                        processRemoveCollection(s, objectID);

                                                }

                                        }
                                        //add or remove subcommunity to the community, the event is issued AFTER collection is added/removed to/from the community
                                        if (event.getObjectType() == Constants.COMMUNITY) {

                                                if (et == Event.REMOVE) {
                                                        log.warn(" processing removing community");
                                                        processRemoveCommunity(s, objectID);

                                                }
                                        }
                                //we work on community itself not on it's elements
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
                        }
                }

                if(st==Constants.COLLECTION ) {
                        Collection s = (Collection) event.getSubject(ctx);
                        if(s!=null) {
                                log.warn(" processing removing item "+ event.getDetail());
                                if (et == Event.REMOVE ) {
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


                if (st==Constants.ITEM && et == Event.MODIFY && event.getDetail().equals("WITHDRAW")) {
                        Item s = (Item) event.getSubject(ctx);
                        Collection[] cols =s.getCollections();
                        for (Collection col:cols) {
                                if (col.countItems() == 0){
                                        log.warn(" processing removing item");
                                        processRemoveItem(col);

                                }
                        }
                }


                if(st==Constants.GROUP ) {
                        if(event.getObject(ctx)!=null && event.getObjectType()==Constants.EPERSON) {
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

                       /* if(resourceType== Constants.COLLECTION) {
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
                        }*/
                }
        }

        private void processAddItem( Collection col ) throws java.sql.SQLException {

                       /* if(ListUserCommunities.emptyCollections!=null
                                && ListUserCommunities.emptyCollections.contains(col)) {
                                ListUserCommunities.removeCollectionFromEmptyList(col);
                                if(!col.isPrivate()) {
                                        ListUserCommunities.removeUsersFromAuthorizedColList(col);
                                        ListUserCommunities.addCollectionToAnnonList(col);
                                }

                        }*/
        }

        private void processRemoveItem( Collection col ) throws java.sql.SQLException {
                             /*  ListUserCommunities.addCollectionToEmptyList(col);
                                if( !ListUserCommunities.privateCollections.contains(col)) {
                                        ListUserCommunities.removeCollectionFromAnnonList(col);
                                }*/

        }

        private void processAddCollection( Community comm, Collection col ) throws java.sql.SQLException {

               /* log.warn("We continue adding collection");
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
                }*/


        }

        private void processAddCommunity( Community comm ) throws java.sql.SQLException {

                /*ListUserCommunities.addCommunityToAdminList(comm);
                ListUserCommunities.addUsersToAuthorizedComList(comm);*/


        }

        private void processRemoveCollection( Community comm, int collectionID ) throws java.sql.SQLException {

                /*ListUserCommunities.removeCollectionFromAnnonListID(comm,collectionID);
                ListUserCommunities.removeCollectionFromAdminListID(comm,collectionID);
                ListUserCommunities.removeCollectionFromEmptyListID(collectionID);
                ListUserCommunities.removeCollectionFromPrivateListID(collectionID);
                ListUserCommunities.removeCollectionFromNYUOnlyListID(collectionID);
                ListUserCommunities.removeCollectionFromGallatinOnlyListID(collectionID);*/

        }

        private void processRemoveCommunity( Community parentComm, int communityID ) throws java.sql.SQLException {

               /* ListUserCommunities.removeCommunityFromAdminListID(parentComm,communityID);
                ListUserCommunities.removeCommunityFromAnnonListID(parentComm,communityID);*/

        }

        private void processDeleteCommunity(  int communityID ) throws java.sql.SQLException {

               /* ListUserCommunities.removeChildrenCommunityFromAdminListID(communityID);
                ListUserCommunities.removeChildrenCommunityFromAnnonListID(communityID);*/

        }

        private void processCreateCommunity(  Community comm ) throws java.sql.SQLException {

               /* ListUserCommunities.addCommunityToAdminListID(comm.getID());
                ListUserCommunities.addUsersToAuthorizedComList(comm);*/

        }

        private void processUpdateCollection(Collection col) throws java.sql.SQLException {
                /*ListUserCommunities.updateCollectionMetadata(col, true);
                ListUserCommunities.updateCollectionMetadata(col, false);*/
        }

        private void processUpdateCommunity(Community comm) throws java.sql.SQLException {
               /* ListUserCommunities.updateCommunityMetadata(comm, true);
                ListUserCommunities.updateCommunityMetadata(comm, false);*/

        }
}
