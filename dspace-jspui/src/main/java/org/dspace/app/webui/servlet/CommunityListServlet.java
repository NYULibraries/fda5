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

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.dspace.app.util.ListUserCommunities;
import org.dspace.app.webui.components.ListCommunities;
import org.dspace.app.webui.util.JSPManager;
import org.dspace.authorize.AuthorizeException;
import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.core.Context;
import org.dspace.core.LogManager;

/**
 * Servlet for listing communities (and collections within them)
 * 
 * @author Robert Tansley,
 *  @version $Revision$
 * modified by Kate Pechekhonova to re-use method for creating  subcommunities and collections from org.dspace.app.util.ListUserCommunities
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

            colMap = new HashMap<Integer, Collection[]>();
            commMap = new HashMap<Integer, Community[]>();

            if(context.getCurrentUser()==null)
            {
                    ListUserCommunities.ListAnonUserCommunities();
                    colMap = ListUserCommunities.colMapAnon;
                    commMap = ListUserCommunities.commMapAnon;
            }
            else
            {
                ListCommunities comList = new ListCommunities();
                comList.ListUserCommunities(context);
                colMap = comList.getCollectionsMap();
                commMap = comList.getCommunitiesMap();
                // can they admin communities?
                if (AuthorizeManager.isAdmin(context)) {
                    // set a variable to create an edit button
                    request.setAttribute("admin_button", Boolean.TRUE);
                }
            }
                request.setAttribute("communities", communities);
                request.setAttribute("collections.map", colMap);
                request.setAttribute("subcommunities.map", commMap);
            JSPManager.showJSP(request, response, "/community-list.jsp");
        }
}
