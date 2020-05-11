<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>

<%--
  - Display hierarchical list of communities and collections
  -
  - Attributes to be passed in:
  -    communities         - array of communities
  -    collections.map  - Map where a keys is a community IDs (Integers) and 
  -                      the value is the array of collections in that community
  -    subcommunities.map  - Map where a keys is a community IDs (Integers) and 
  -                      the value is the array of subcommunities in that community
  -    admin_button - Boolean, show admin 'Create Top-Level Community' button
  --%>

<%@page import="org.dspace.content.Bitstream"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
	
<%@ page import="org.dspace.app.webui.servlet.admin.EditCommunitiesServlet" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.browse.ItemCountException" %>
<%@ page import="org.dspace.browse.ItemCounter" %>
<%@ page import="org.dspace.content.Collection" %>
<%@ page import="org.dspace.content.Community" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.Map" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%
    Community[] communities = (Community[]) request.getAttribute("communities");
    Map collectionMap = (Map) request.getAttribute("collections.map");
    Map subcommunityMap = (Map) request.getAttribute("subcommunities.map");
    Boolean admin_b = (Boolean)request.getAttribute("admin_button");
    boolean admin_button = (admin_b == null ? false : admin_b.booleanValue());
%>

<%! //we use the same function 2 times so probably we should convert it to jsp tag but we can change something here so will leave for now
	void showCommunity(Community c, JspWriter out, HttpServletRequest request, Map collectionMap, Map subcommunityMap) throws ItemCountException, IOException, SQLException
	{

          if (subcommunityMap.containsKey(c.getID()) || collectionMap.containsKey(c.getID()) )
           {
                    // Get the sub-communities in this community
                    Community[] comms = (Community[]) subcommunityMap.get(c.getID());

                     // Get the collections in this community
                     Collection[] cols = (Collection[]) collectionMap.get(c.getID());

                      out.println( "<li role=\"treeitem\" >");
                      out.println( "<span  class=\"t1\"><a href=\"" + request.getContextPath() + "/handle/"
                                           + c.getHandle() + "\">" + c.getMetadata("name") + "</a></span>");
                      out.println( "<ul role=\"group\" style=\"display:none \">" );

                    if (comms != null && comms.length > 0)
                    {

                        for (int k = 0; k < comms.length; k++)
                        {
                            showCommunity(comms[k], out, request, collectionMap, subcommunityMap);
                        }

                    }

                    if (cols != null && cols.length > 0)
                    {

                        for (int j = 0; j < cols.length; j++)
                        {
                          out.println("<li class=\"tree-collections-list\" role=\"treeitem\" >");
                          //String collName =  ( StringUtils.isNotBlank(cols[j].getMetadata("name"))  ? cols[j].getMetadata("name") : "Untitled" );
                          out.println("<span  class=\"t1 ct1\"><a href=\"" + request.getContextPath() + "/handle/" + cols[j].getHandle() + "\">" + cols[j].getMetadata("name") +"</a></span>");
                          if (cols[j].isNYUOnly(UIUtil.obtainContext(request)))
                          {
                            out.println("<span class=\"nyu-only-svg\"><svg version=\"1.1\"  xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" viewBox=\"0 0 100.69 13.76\" style=\"enable-background:new 0 0 100.69 13.76;\" xml:space=\"preserve\">");
        		              out.println("<style type=\"text/css\"> path{fill:#57068C;} </style>");
        		              out.println("<g><path  d=\"M0,0.23h2.17l7.12,9.19V0.23h2.3v13.3H9.63L2.3,4.07v9.46H0C0,13.53,0,0.23,0,0.23z\"/><path  d=\"M18.92,8.29l-5.28-8.05h2.77l3.7,5.87l3.76-5.87h2.68l-5.28,8v5.3h-2.36V8.29H18.92z\"/><path  d=\"M28.4,7.89V0.23h2.34v7.56c0,2.47,1.27,3.78,3.36,3.78c2.07,0,3.34-1.23,3.34-3.69V0.22h2.34v7.54c0,3.97-2.24,5.97-5.72,5.97C30.61,13.74,28.4,11.74,28.4,7.89z\"/>");
        			            out.println(" <path d=\"M48.11,6.92V6.88C48.11,3.14,51,0,55.08,0s6.93,3.1,6.93,6.84v0.04c0,3.74-2.89,6.88-6.97,6.88S48.11,10.66,48.11,6.92z M59.56,6.92V6.88c0-2.58-1.88-4.73-4.52-4.73s-4.48,2.11-4.48,4.69v0.04c0,2.58,1.88,4.71,4.52,4.71S59.56,9.5,59.56,6.92z\"/><path d=\"M64,0.23h2.17l7.12,9.19V0.23h2.3v13.3h-1.96L66.3,4.07v9.46H64V0.23z\"/><path d=\"M79,0.23h2.34V11.4h6.99v2.13H79C79,13.53,79,0.23,79,0.23z\"/><path d=\"M92.21,8.29l-5.28-8.05h2.77l3.7,5.87l3.76-5.87h2.68l-5.28,8v5.3H92.2V8.29H92.21z\"/></g></svg></span>");
                          }
                          out.println("</li>");
                        }

                    }

                    out.println( "</ul>" );

                    out.println("</li>");
           }
    }
%>

<dspace:layout locbar="commLink" titlekey="jsp.community-list.title">

<%
    if (admin_button)
    {
%>     
<dspace:sidebar>
			<div class="panel panel-admin-tools">
			<div class="panel-heading">
				<fmt:message key="jsp.admintools"/>
				<span class="pull-right">
					<dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.site-admin\")%>"><fmt:message key="jsp.adminhelp"/></dspace:popup>
				</span>
			</div>
			<div class="panel-body">
                <form method="post" action="<%=request.getContextPath()%>/dspace-admin/edit-communities">
                    <input type="hidden" name="action" value="<%=EditCommunitiesServlet.START_CREATE_COMMUNITY%>" />
					<input class="btn btn-default" type="submit" name="submit" value="<fmt:message key="jsp.community-list.create.button"/>" />
                </form>
            </div>
</dspace:sidebar>
<%
    }
%>
	<h1 id="page-title"><fmt:message key="jsp.community-list.title"/></h1>
	<p><fmt:message key="jsp.community-list.text1"/></p>

<% if (communities.length != 0)
{
%>
<div class="fda-tree">
<%
        for (int i = 0; i < communities.length; i++)
        {%>
        <ul role="tree">
        <%    showCommunity(communities[i], out, request, collectionMap, subcommunityMap); %>
        </ul>
        <%}

%>
    </ul>
</div> 
<% }
%>
</dspace:layout>
