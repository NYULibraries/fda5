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
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

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

        CopyOnWriteArrayList nyuOnly = ListUserCommunities.nyuOnly;

        //if generic communities list was not build before for some reasons try to build it now
        if(ListUserCommunities.colMapAnon==null && ListUserCommunities.commMapAnon==null) {
            try {
                ListUserCommunities.PrebuildFrontListsCommunities();
            } catch (Exception e) {
                throw new ServletException(e.getMessage(), e);
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
                    if ( ListUserCommunities.checkAuthorizedCollections(userID)
                            || ListUserCommunities.checkAuthorizedCommunities(userID) ) {
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
            } catch (Exception e) {
                throw new ServletException(e.getMessage(), e);
            }

        }
        //Used to add nyuOnly icon or gallatinOnly on main or community page
        request.setAttribute("nyuOnly", ListUserCommunities.nyuOnly);
        request.setAttribute("gallatinOnly", ListUserCommunities.gallatinOnly);
        request.setAttribute("communities", communities);
        JSPManager.showJSP(request, response, "/community-list.jsp");
    }
}
