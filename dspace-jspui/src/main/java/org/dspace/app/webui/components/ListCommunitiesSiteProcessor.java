/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.webui.components;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.dspace.frontlist.ListUserCommunities;
import org.dspace.frontlist.ListCommunities;
import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.core.Context;
import org.dspace.eperson. EPerson;
import org.dspace.frontlist.ListCommunities;
import org.dspace.plugin.PluginException;
import org.dspace.plugin.SiteHomeProcessor;


/**
 * This class add collections and subcomminities maps to the request attributes to use in
 * the site home  implementing the SiteHomeProcessor.
 *
 * @author Kate Pechekhonova
 *
 */
public class ListCommunitiesSiteProcessor implements SiteHomeProcessor
{

    /** log4j category */
    private static final Logger log = Logger.getLogger(ListCommunitiesSiteProcessor.class);

    /**
     * blank constructor - does nothing.
     *
     */
    public ListCommunitiesSiteProcessor()
    {

    }

    @Override
    public void process(Context context, HttpServletRequest request,
                        HttpServletResponse response) throws PluginException
    {

        //if generic communities list was not build before for some reasons try to build it now
        if(ListUserCommunities.colMapAnon==null && ListUserCommunities.commMapAnon==null) {
            try {
                ListUserCommunities.PrebuildFrontListsCommunities();
            } catch (Exception e) {
                throw new PluginException(e.getMessage(), e);
            }
        }

        //now start buildinhg community list tailored for the user
        EPerson user = context.getCurrentUser();

        //for anonymous user just show generic list
        if (user == null) {
            request.setAttribute("collections.map", ListUserCommunities.colMapAnon);
            request.setAttribute("subcommunities.map", ListUserCommunities.commMapAnon);

        } else {
            try {
                //for site admin user show admin list
                if (AuthorizeManager.isAdmin(context)) {
                    request.setAttribute("collections.map", ListUserCommunities.colMapAdmin);
                    request.setAttribute("subcommunities.map", ListUserCommunities.commMapAdmin);
                } else {
                    int userID = user.getID();

                    //if a user is not a site admin, check if the user is admin of some private or empty collections or communities
                    //generate tailored list of communities which include those collections and communities
                    Collection[] cols = ListUserCommunities.getAuthorizedCollections(userID,context);
                    Community[] comms = ListUserCommunities.getAuthorizedCommunities(userID,context);

                    if ( cols!=null || comms!=null ) {
                        Map colMap = new HashMap<Integer, Collection[]>();
                        Map commMap = new HashMap<Integer, Community[]>();

                        ListCommunities comList = new ListCommunities();
                        comList.BuildUserCommunitiesList(context);
                        if (comList.getCollectionsMap() != null) {
                            colMap.putAll(comList.getCollectionsMap());
                        }
                        if (comList.getCommunitiesMap() != null) {
                            commMap.putAll(comList.getCommunitiesMap());
                        }
                        request.setAttribute("collections.map",colMap);
                        request.setAttribute("subcommunities.map",commMap);
                    //if user does not have access to empty or private collections and communities show generic list
                    } else {
                        request.setAttribute("collections.map", ListUserCommunities.colMapAnon);
                        request.setAttribute("subcommunities.map", ListUserCommunities.commMapAnon);
                    }

                }
            } catch (SQLException e) {
                throw new PluginException(e.getMessage(), e);
            }

        }
        //Used to add nyuOnly icon on main or community page
        request.setAttribute("nyuOnly", ListUserCommunities.nyuOnly);

    }

}
