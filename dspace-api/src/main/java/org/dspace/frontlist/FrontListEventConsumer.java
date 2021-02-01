package org.dspace.frontlist;

import org.apache.log4j.Logger;

import java.util.*;

import org.apache.log4j.Logger;
import org.dspace.authorize.AuthorizeManager;
import org.dspace.authorize.ResourcePolicy;
import org.dspace.content.DSpaceObject;
import org.dspace.core.Constants;
import org.dspace.content.Item;
import org.dspace.content.Collection;
import org.dspace.core.Context;
import org.dspace.event.Consumer;
import org.dspace.event.Event;
import org.dspace.app.util.ListUserCommunities;
import org.dspace.content.Community;
import org.dspace.eperson.EPerson;
import org.dspace.eperson.Group;

import java.util.HashMap;


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

                if (st != Constants.COLLECTION && st!= Constants.GROUP && st!= Constants.COMMUNITY && st!= Constants.SITE ) {
                        log
                                .warn("FrontListConsumer should not have been given this kind of Subject in an event, skipping: "
                                        + event.toString());
                        return;
                }
                if(st==Constants.COLLECTION ) {
                        if(event.getObject(ctx)!=null && event.getObjectType()==Constants.ITEM ) {
                                processAddItem((Item) event.getObject(ctx));
                        }
                }

                if(st==Constants.GROUP ) {
                        if(event.getObject(ctx)!=null && event.getObjectType()==Constants.COLLECTION) {
                                processAddEperson(ctx, (EPerson) event.getObject(ctx), (Group) event.getSubject(ctx));
                        }
                }

                if(st==Constants.COMMUNITY ) {
                        int et = event.getEventType();
                        if(et==Constants.ADD) {
                                if(event.getObject(ctx)!=null
                                        && (event.getObjectType()==Constants.COLLECTION || event.getObjectType()==Constants.COMMUNITY)) {
                                        ListUserCommunities.ListAnonUserCommunities();
                                }
                        }
                }

                if(st==Constants.SITE ) {
                        int et = event.getEventType();
                        if(et==Constants.ADD) {
                                if(event.getObject(ctx)!=null
                                        &&  event.getObjectType()==Constants.COMMUNITY) {
                                        ListUserCommunities.ListAnonUserCommunities();
                                }
                        }
                }

                }



        /**
         * Process sets of objects to add, update, and delete in index. Correct for
         * interactions between the sets -- e.g. objects which were deleted do not
         * need to be added or updated, new objects don't also need an update, etc.
         */
        public void end(Context ctx) throws Exception {


        }

        public void finish(Context ctx) throws Exception {
            // No-op

        }

        private void processAddEperson( Context context, EPerson eperson, Group group ) throws java.sql.SQLException {
                List<ResourcePolicy> rps= AuthorizeManager.getPoliciesForGroup(context, group);
                for (ResourcePolicy rp:rps) {
                        int resourceID = rp.getResourceID();
                        int resourceType = rp.getResourceType();
                        int epersonID = eperson.getID();

                        if(resourceType== Constants.COLLECTION) {
                                Collection  col =(Collection) DSpaceObject.find(context, resourceType, resourceID );
                                if((ListUserCommunities.privateCollections!=null && ListUserCommunities.privateCollections.contains(col) )||
                                        (ListUserCommunities.emptyCollections!=null && ListUserCommunities.emptyCollections.contains(col)) ) {

                                        ListUserCommunities.ListAnonUserCommunities();
                                }
                        }
                        if(resourceType== Constants.COMMUNITY) {
                                Community  com =(Community) DSpaceObject.find(context, resourceType, resourceID );
                                if(com.getAllCollections().length==0) {

                                        ListUserCommunities.ListAnonUserCommunities();
                                }
                        }
                        if(resourceType== Constants.GROUP) {
                                Group  parentGroup =(Group) DSpaceObject.find(context, resourceType, resourceID );
                                processAddEperson(context, eperson, parentGroup);
                        }
                }
        }

        private void processAddItem( Item item ) throws java.sql.SQLException {



                Collection[] colls =  item.getCollections();


                for (Collection col:colls) {
                        if ( ListUserCommunities.emptyCollections.contains(col)) {
                                ListUserCommunities.ListAnonUserCommunities();
                                break;
                        }

                }


        }


}
