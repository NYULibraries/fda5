<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Community home JSP
  -
  - Attributes required:
  -    community             - Community to render home page for
  -    collections           - array of Collections in this community
  -    subcommunities        - array of Sub-communities in this community
  -    last.submitted.titles - String[] of titles of recently submitted items
  -    last.submitted.urls   - String[] of URLs of recently submitted items
  -    admin_button - Boolean, show admin 'edit' button
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="org.dspace.app.webui.components.RecentSubmissions" %>

<%@ page import="org.dspace.app.webui.servlet.admin.EditCommunitiesServlet" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.browse.BrowseIndex" %>
<%@ page import="org.dspace.browse.ItemCounter" %>
<%@ page import="org.dspace.content.*" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.concurrent.locks.*" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.io.IOException" %>
<%@ page import="org.dspace.browse.ItemCountException" %>
<%!   public Map<Integer, Collection[]> collectionMap; %>
   <%!   public Map<Integer, Community[]> subcommunityMap; %>
     <%   collectionMap = new HashMap<Integer, Collection[]>(); %>
     <%   subcommunityMap = new HashMap<Integer, Community[]>(); %>
<%
    // Retrieve attributes
    Community community = (Community) request.getAttribute( "community" );
    Collection[] collections =
        (Collection[]) request.getAttribute("collections");
    Community[] subcommunities =
        (Community[]) request.getAttribute("subcommunities");
    

            for (int com = 0; com < subcommunities.length; com++)
            {
               build(subcommunities[com]);
            }

    RecentSubmissions rs = (RecentSubmissions) request.getAttribute("recently.submitted");
    
    Boolean editor_b = (Boolean)request.getAttribute("editor_button");
    boolean editor_button = (editor_b == null ? false : editor_b.booleanValue());
    Boolean add_b = (Boolean)request.getAttribute("add_button");
    boolean add_button = (add_b == null ? false : add_b.booleanValue());
    Boolean remove_b = (Boolean)request.getAttribute("remove_button");
    boolean remove_button = (remove_b == null ? false : remove_b.booleanValue());

	// get the browse indices
    BrowseIndex[] bis = BrowseIndex.getBrowseIndices();

    // Put the metadata values into guaranteed non-null variables
    String name = community.getMetadata("name");
    String intro = community.getMetadata("introductory_text");
    String copyright = community.getMetadata("copyright_text");
    String sidebar = community.getMetadata("side_bar_text");
    Bitstream logo = community.getLogo();
    
    boolean feedEnabled = ConfigurationManager.getBooleanProperty("webui.feed.enable");
    String feedData = "NONE";
    if (feedEnabled)
    {
        feedData = "comm:" + ConfigurationManager.getProperty("webui.feed.formats");
    }
    
    ItemCounter ic = new ItemCounter(UIUtil.obtainContext(request));
%>

<%!
    void showCommunity(Community c, JspWriter out, HttpServletRequest request, ItemCounter ic, Map collectionMap, Map subcommunityMap) throws ItemCountException, IOException, SQLException
    {
        out.println( "<li>" );
        out.println( "<h4><a href=\"" + request.getContextPath() + "/handle/"
                + c.getHandle() + "\">" + c.getMetadata("name") + "</a></h4>");
        // Get the collections in this community
        Collection[] cols = (Collection[]) collectionMap.get(c.getID());
        if (cols != null && cols.length > 0)
        {
        out.println( "<ul>" );
            for (int j = 0; j < cols.length; j++)
            {
                out.println("<li>");
                out.println("<h4><a href=\"" + request.getContextPath() + "/handle/" + cols[j].getHandle() + "\">" + cols[j].getMetadata("name") +"</a></h4>");
                out.println("</li>");
            }
        out.println( "</ul>" );
        }
        // Get the sub-communities in this community
        Community[] comms = (Community[]) subcommunityMap.get(c.getID());
        if (comms != null && comms.length > 0)
        {
        out.println( "<ul>" );
            for (int k = 0; k < comms.length; k++)
            {
               showCommunity(comms[k], out, request, ic, collectionMap, subcommunityMap);
            }
        out.println( "</ul>" );
        }
        out.println("</li>");
    }
%>

<%@page import="org.dspace.app.webui.servlet.MyDSpaceServlet"%>
<dspace:layout locbar="commLink" title="<%= name %>" feedData="<%= feedData %>">
<div class="container">
<div class="row">
	<div class="col-md-8">
        <div class="page-title-area">
        <h2><%= name %> <small>Community home page</small></h2>
         </div>
<%  if (logo != null) { %>
     <div class="col-md-4">
     	<img class="img-responsive" alt="Logo" src="<%= request.getContextPath() %>/retrieve/<%= logo.getID() %>" />
     </div> 
<% } %>
<div class="panel panel-primary">
  <div class="panel-heading">Search within this community:</div>
  <div class="panel-body">
  <form method="get" action="simple-search" class="simplest-search">
 <div class="form-group-flex">
   <div class="input-hold">
      <input type="text" class="form-control" placeholder="Titles, authors, keywords..." name="query" id="tequery" ></div>
   <div class="button-hold">   <button type="submit" class="btn btn-primary"><span class="glyphicon glyphicon-search"></span></button></div>
   </div>
  </form>
</div>
</div>
<div class="row">
        <%@ include file="discovery/static-tagcloud-facet.jsp" %>
</div>
<div>
<section class="collections-list">
        <div class="fda-tree">
<%
	boolean showLogos = ConfigurationManager.getBooleanProperty("jspui.community-home.logos", true);
	if (subcommunities.length != 0)
    {
%>
		<h3>Collections and sub-communities</h3>
<%
        for (int j = 0; j < subcommunities.length; j++)
        {
%>
        <ul>
          <%  showCommunity(subcommunities[j], out, request, ic, collectionMap, subcommunityMap);%>
        </ul>
        <% }
%>
<%
    }
%>

<%
    if (collections.length != 0)
    { %>
<ul>
            <%for (int j = 0; j < collections.length; j++)
            {%>
                <li>
                 <h4><a href="<%= request.getContextPath() %>/handle/<%= collections[j].getHandle() %>">
              <%= collections[j].getMetadata("name") %></a></h4>
                </li>
              <% if (remove_button) { %>
              <form class="btn-group" method="post" action="<%=request.getContextPath()%>/tools/edit-communities">
                  <input type="hidden" name="parent_community_id" value="<%= community.getID() %>" />
                  <input type="hidden" name="community_id" value="<%= community.getID() %>" />
                  <input type="hidden" name="collection_id" value="<%= collections[j].getID() %>" />
                  <input type="hidden" name="action" value="<%=EditCommunitiesServlet.START_DELETE_COLLECTION%>" />
                  <button type="submit" class="btn btn-xs btn-danger"><span class="glyphicon glyphicon-trash"></span></button>
              </form>
            <% } %>
        <%} %>

<%
        }
%>
  </div>
</section>
    <% if(editor_button || add_button)  // edit button(s)
    { %>
    <dspace:sidebar>
		 <div class="panel panel-warning">
             <div class="panel-heading">
             	<fmt:message key="jsp.admintools"/>
             	<span class="pull-right">
             		<dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.site-admin\")%>"><fmt:message key="jsp.adminhelp"/></dspace:popup>
             	</span>
             	</div>
             <div class="panel-body">
             <% if(editor_button) { %>
	            <form method="post" action="<%=request.getContextPath()%>/tools/edit-communities">
		          <input type="hidden" name="community_id" value="<%= community.getID() %>" />
		          <input type="hidden" name="action" value="<%=EditCommunitiesServlet.START_EDIT_COMMUNITY%>" />
                  <%--<input type="submit" value="Edit..." />--%>
                  <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.general.edit.button"/>" />
                </form>
             <% } %>
             <% if(add_button) { %>

				<form method="post" action="<%=request.getContextPath()%>/tools/collection-wizard">
		     		<input type="hidden" name="community_id" value="<%= community.getID() %>" />
                    <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.community-home.create1.button"/>" />
                </form>
                
                <form method="post" action="<%=request.getContextPath()%>/tools/edit-communities">
                    <input type="hidden" name="action" value="<%= EditCommunitiesServlet.START_CREATE_COMMUNITY%>" />
                    <input type="hidden" name="parent_community_id" value="<%= community.getID() %>" />
                    <%--<input type="submit" name="submit" value="Create Sub-community" />--%>
                    <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.community-home.create2.button"/>" />
                 </form>
             <% } %>
            <% if( editor_button ) { %>
                <form method="post" action="<%=request.getContextPath()%>/mydspace">
                  <input type="hidden" name="community_id" value="<%= community.getID() %>" />
                  <input type="hidden" name="step" value="<%= MyDSpaceServlet.REQUEST_EXPORT_ARCHIVE %>" />
                  <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.mydspace.request.export.community"/>" />
                </form>
              <form method="post" action="<%=request.getContextPath()%>/mydspace">
                <input type="hidden" name="community_id" value="<%= community.getID() %>" />
                <input type="hidden" name="step" value="<%= MyDSpaceServlet.REQUEST_MIGRATE_ARCHIVE %>" />
                <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.mydspace.request.export.migratecommunity"/>" />
              </form>
               <form method="post" action="<%=request.getContextPath()%>/dspace-admin/metadataexport">
                 <input type="hidden" name="handle" value="<%= community.getHandle() %>" />
                 <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.general.metadataexport.button"/>" />
               </form>
			<% } %>
			</div>
		</div>
  </dspace:sidebar>
    <% } %>
</dspace:layout>
<%! private void build(Community c) throws SQLException {

        Integer comID = Integer.valueOf(c.getID());

        // Find collections in community
        Collection[] colls = c.getCollections();
        collectionMap.put(comID, colls);

        // Find subcommunties in community
        Community[] comms = c.getSubcommunities();

        // Get all subcommunities for each communities if they have some
        if (comms.length > 0)
        {
            subcommunityMap.put(comID, comms);

            for (int sub = 0; sub < comms.length; sub++) {

                build(comms[sub]);
            }
        }
    }
%>
