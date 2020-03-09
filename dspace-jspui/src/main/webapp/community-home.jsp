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
<%@ page import="org.dspace.app.webui.components.MostDownloaded" %>

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
	MostDownloaded mostdownloaded = (MostDownloaded) request.getAttribute("most.downloaded");
	
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
		out.println( "<li role=\"treeitem\" >" );
		out.println( "<span  class=\"t1\"><a href=\"" + request.getContextPath() + "/handle/"
				+ c.getHandle() + "\">" + c.getMetadata("name") + "</a></span>");
		// Get the collections in this community
		Collection[] cols = (Collection[]) collectionMap.get(c.getID());
		if (cols != null && cols.length > 0)
		{
		out.println( "<ul role=\"group\" >" );
			for (int j = 0; j < cols.length; j++)
			{
				out.println("<li>");
				out.println("<span  class=\"t1\"><a href=\"" + request.getContextPath() + "/handle/" + cols[j].getHandle() + "\">" + cols[j].getMetadata("name") +"</a></span>");
				out.println("</li>");
			}
		out.println( "</ul>" );
		}
		// Get the sub-communities in this community
		Community[] comms = (Community[]) subcommunityMap.get(c.getID());
		if (comms != null && comms.length > 0)
		{
			out.println( "<ul role=\"group\" >" );
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

<header class="page-title-area">
  
  <%  if (logo != null) { %>
  <div class="img-hold">
	  <img class="img-responsive" alt="Logo" src="<%= request.getContextPath() %>/retrieve/<%= logo.getID() %>" />
  </div> 
  <% } %>
 <h1  id="page-title"><%= name %></h1>

 <%
 if (StringUtils.isNotBlank(intro)) { %>

	<div class="community-intro"><%= intro %></div>
 
 <%  } %>	
</header>

<section class="search-area"  role="search">
	<h2 class="sr-only">Search in this community </h2>
  	<form method="get" action="/handle/<%= community.getHandle() %>/simple-search " class="simplest-search">
	<div class="form-group-flex">
	  <div class="input-hold"><input aria-label="search"  type="text" class="form-control" placeholder="Search titles, authors, keywords..." name="query" id="tequery" ></div>
	  <div class="button-hold">   <button aria-label="submit" type="submit" class="btn btn-primary"><span aria-hidden="true" class="glyphicon glyphicon-search"></span></button></div>
	</div>
  </form>
</section>

<%@ include file="discovery/static-tagcloud-facet.jsp" %>

<section class="collections-list">
	<div class="fda-tree">
<%
  boolean showLogos = ConfigurationManager.getBooleanProperty("jspui.community-home.logos", true);
  if (subcommunities.length != 0)
	{
%>
	<h2 class="section-title">Subcommunities</h2>
<%
		for (int j = 0; j < subcommunities.length; j++)
		{
%>
		<ul role="tree">
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
		<h2 class="section-title">Collections</h2>
  <ul>
			<%for (int j = 0; j < collections.length; j++)
			<% if (collections[j].countItems()>0) { %>
			{%>
				<li>
				 <span class="t1"><a href="<%= request.getContextPath() %>/handle/<%= collections[j].getHandle() %>">
			  <%= collections[j].getMetadata("name") %> </a>
			  <% if (collections[j].isNYUOnly()) { %>
			  <span class="nyu-only-svg">
			
				<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
				viewBox="0 0 100.69 13.76" style="enable-background:new 0 0 100.69 13.76;" xml:space="preserve">
		   <style type="text/css">
			   .st0{fill:#57068C;}
		   </style>
		   <g>
			   <path class="st0" d="M0,0.23h2.17l7.12,9.19V0.23h2.3v13.3H9.63L2.3,4.07v9.46H0C0,13.53,0,0.23,0,0.23z"/>
			   <path class="st0" d="M18.92,8.29l-5.28-8.05h2.77l3.7,5.87l3.76-5.87h2.68l-5.28,8v5.3h-2.36V8.29H18.92z"/>
			   <path class="st0" d="M28.4,7.89V0.23h2.34v7.56c0,2.47,1.27,3.78,3.36,3.78c2.07,0,3.34-1.23,3.34-3.69V0.22h2.34v7.54
				   c0,3.97-2.24,5.97-5.72,5.97C30.61,13.74,28.4,11.74,28.4,7.89z"/>
			   <path class="st0" d="M48.11,6.92V6.88C48.11,3.14,51,0,55.08,0s6.93,3.1,6.93,6.84v0.04c0,3.74-2.89,6.88-6.97,6.88
				   S48.11,10.66,48.11,6.92z M59.56,6.92V6.88c0-2.58-1.88-4.73-4.52-4.73s-4.48,2.11-4.48,4.69v0.04c0,2.58,1.88,4.71,4.52,4.71
				   S59.56,9.5,59.56,6.92z"/>
			   <path class="st0" d="M64,0.23h2.17l7.12,9.19V0.23h2.3v13.3h-1.96L66.3,4.07v9.46H64V0.23z"/>
			   <path class="st0" d="M79,0.23h2.34V11.4h6.99v2.13H79C79,13.53,79,0.23,79,0.23z"/>
			   <path class="st0" d="M92.21,8.29l-5.28-8.05h2.77l3.7,5.87l3.76-5.87h2.68l-5.28,8v5.3H92.2V8.29H92.21z"/>
		   </g>
		   		</svg>
			</span>
			<% }  %>
		</span>
			 
			  <%
			  if (StringUtils.isNotBlank(collections[j].getMetadata("short_description")))  	
			  { %>
			  <div class="collection-short-description"><%= collections[j].getMetadata("short_description") %></div>

			  <%
				} else {
			  %>
			  <div class="collection-short-description collection-short-description-none">No description available</div>
			  <%
				}  
			  %>
				</li>
            <% } %>
		<%} %>
  </ul>
<%
		}
%>
  </div>
</section>

	<dspace:sidebar>
	<aside class="sidebar">
	<%if (mostdownloaded != null && mostdownloaded.count() > 0)
	{
	%>
						 <div class="panel panel-primary most-downloaded">
						   <div class="panel-heading">
                        	<h2 class="panel-title">Most downloaded</h2>
                      		</div>
						   <div class="panel-body">

						<%

						for (Item item : mostdownloaded.getMostDownloaded())
						{

						  if(item.isPublic()||editor_button) {
                                                    if(item.getCollections().length>0) {
							Collection col=item.getCollections()[0];
							Metadatum[] dcv = item.getMetadata("dc", "title", null, Item.ANY);
							String displayTitle = "Untitled";
							if (dcv != null & dcv.length > 0)
							{
								displayTitle = dcv[0].value;
							}
							dcv = item.getMetadata("dc", "contributor", "author", Item.ANY);
							Metadatum[] authors =dcv;

					%>
						<article >
						  <div class="communityflag"><span>Collection:</span>
							<a href="<%= request.getContextPath() %>/handle/<%=col.getHandle() %>" ><%= col.getName()  %></a></div>
							<h3 class="article-title"><a href="<%= request.getContextPath() %>/handle/<%=item.getHandle() %>"><%= displayTitle %></a></h3>
							<% if (dcv!=null&&dcv.length>0)
								{
								 for(int i=0;i<authors.length;i++)
								 {
								   String authorQuery=""+request.getContextPath()+"/simple-search?filterquery="
												 +URLEncoder.encode(authors[i].value,"UTF-8")
												 + "&amp;filtername="+URLEncoder.encode("author","UTF-8")+"&amp;filtertype="
												 +URLEncoder.encode("equals","UTF-8");
							%>
								 <div class="authors">
								 <a class="authors" href="<%=authorQuery %>"> <%= StringUtils.abbreviate(authors[i].value,36) %></a>
								 </div>
							   <% }
							   } %>
					   </article>
					  <%
                                            }
					   }
					  }

	%>     </div>
			</div>
		<%} %>
			   <% if(editor_button || add_button)  // edit button(s)
				  { %>
	 <div class="panel panel-admin-tools">
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
	  </div>
	</div>
	<% } %>
</aside>
   </dspace:sidebar>
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
