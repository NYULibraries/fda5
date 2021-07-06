/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.webui.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.dspace.frontlist.ListUserCommunities;
import org.dspace.frontlist.ListCommunities;
import org.dspace.app.webui.util.JSPManager;
import org.dspace.authorize.AuthorizeException;
import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.core.Context;
import org.dspace.core.LogManager;
import org.dspace.eperson.EPerson;

/**
 * Servlet for listing communities (and collections within them)
 * 
 * @author Robert Tansley,
 *  @version $Revision$
 * modified by Kate Pechekhonova to re-use method for creating  subcommunities and collections from org.dspace.frontlist.ListUserCommunities
 * instead of building it here
 *
 */
public class CommunityListServlet extends DSpaceServlet {

    // This will map community IDs to arrays of collections
    private Map<Integer, Collection[]> colMap;

    // This will map communityIDs to arrays of sub-communities
    private Map<Integer, Community[]> commMap;

    /**
     * log4j category
     */
    private static Logger log = Logger.getLogger(CommunityListServlet.class);

    protected void doDSGet(Context context, HttpServletRequest request,
                           HttpServletResponse response) throws ServletException, IOException,
            SQLException, AuthorizeException {


        log.info(LogManager.getHeader(context, "view_community_list", ""));

        // Get the top communities to shows in the community list
        Community[] communities = Community.findAllTop(context);

        ArrayList<Collection> nyuOnly = ListUserCommunities.nyuOnly;

        if (ListUserCommunities.colMapAnon == null && ListUserCommunities.commMapAnon == null) {
            try {
                ListUserCommunities.ListAnonUserCommunities();
            } catch (SQLException e) {
                log.error(e.getMessage(), e);
            }
        }

        EPerson user = context.getCurrentUser();

        if (user == null) {
            // Get the top communities to shows in the community list
            request.setAttribute("collections.map", ListUserCommunities.colMapAnon);
            request.setAttribute("subcommunities.map", ListUserCommunities.commMapAnon);

        } else {
            try {
                if (AuthorizeManager.isAdmin(context)) {

                    request.setAttribute("collections.map", ListUserCommunities.colMapAdmin);
                    request.setAttribute("subcommunities.map", ListUserCommunities.commMapAdmin);
                    request.setAttribute("admin_button", true);

                } else {
                    int userID = user.getID();
                    if (ListUserCommunities.commAuthorizedUsers.containsKey(userID) || ListUserCommunities.colAuthorizedUsers.containsKey(userID)) {
                        Map colMap = new HashMap<Integer, Collection[]>();
                        Map commMap = new HashMap<Integer, Community[]>();
                        ListCommunities comList = new ListCommunities();
                        comList.ListUserCommunities(context);
                        if (comList.getCollectionsMap() != null) {
                            colMap.putAll(comList.getCollectionsMap());
                        }
                        if (comList.getCommunitiesMap() != null) {
                            commMap.putAll(comList.getCommunitiesMap());
                        }
                        request.setAttribute("collections.map", colMap);
                        request.setAttribute("subcommunities.map", commMap);
                    } else {
                        request.setAttribute("collections.map", ListUserCommunities.colMapAnon);
                        request.setAttribute("subcommunities.map", ListUserCommunities.commMapAnon);
                    }

                }
            } catch (SQLException e) {
                log.error(e.getMessage(), e);
            }

        }
        request.setAttribute("nyuOnly", nyuOnly);
        request.setAttribute("communities", communities);

        JSPManager.showJSP(request, response, "/community-list.jsp");
    }
}
