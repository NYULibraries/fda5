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
import org.dspace.app.util.ListUserCommunities;
import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.core.Context;
import org.dspace.eperson.EPerson;
import org.dspace.plugin.CommunityHomeProcessor;
import org.dspace.plugin.PluginException;



/**
 * This class add collections and subcomminities maps to the request attributes to use in
 * the site home  implementing the SiteHomeProcessor.
 *
 * @author Kate Pechekhonova
 *
 */
public class ListCommunitiesCommunityProcessor implements CommunityHomeProcessor
{

    /** log4j category */
    private static final Logger log = Logger.getLogger(ListCommunitiesSiteProcessor.class);

    /**
     * blank constructor - does nothing.
     *
     */
    public ListCommunitiesCommunityProcessor()
    {

    }

    @Override
    public void process(Context context, HttpServletRequest request,
                        HttpServletResponse response, Community community) throws PluginException
    {

        Map colMap = new HashMap<Integer, Collection[]>();
        Map commMap = new HashMap<Integer, Community[]>();
        ArrayList<Collection> nyuOnly= ListUserCommunities.nyuOnly;

        if(colMap==null && commMap==null) {
            try {
                ListUserCommunities.ListAnonUserCommunities();
            } catch (SQLException e) {
                throw new PluginException(e.getMessage(), e);
            }
        }

        EPerson user = context.getCurrentUser();

        if(user==null)
        {
            log.error(" we do not have user ");
            // Get the top communities to shows in the community list
            colMap = ListUserCommunities.colMapAnon;
            commMap = ListUserCommunities.commMapAnon;


            request.setAttribute("collections.map", colMap);
            request.setAttribute("subcommunities.map", commMap);

        }
        else {
            // Get the top communities to shows in the community list

            try {
                if(AuthorizeManager.isAdmin(context)) {
                    colMap = ListUserCommunities.colMapAdmin;
                    commMap = ListUserCommunities.commMapAdmin;
                } else {
                    int userID = user.getID();
                    log.error(" we are in user"+user.getFirstName());
                    if(ListUserCommunities.commAuthorizedUsers.containsKey(userID)|| ListUserCommunities.colAuthorizedUsers.containsKey(userID) ) {
                        ListCommunities comList = new ListCommunities();
                        comList.ListUserCommunities(context);
                        colMap = comList.getCollectionsMap();
                        commMap = comList.getCommunitiesMap();
                    }
                }
            } catch (SQLException e) {
                throw new PluginException(e.getMessage(), e);
            }

        }

        request.setAttribute("collections.map", colMap);
        request.setAttribute("subcommunities.map", commMap);
        request.setAttribute("nyuOnly", nyuOnly);

    }


}