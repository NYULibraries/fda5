<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Collection home JSP
  -
  - Attributes required:
  -    collection  - Collection to render home page for
  -    community   - Community this collection is in
  -    last.submitted.titles - String[], titles of recent submissions
  -    last.submitted.urls   - String[], corresponding URLs
  -    logged.in  - Boolean, true if a user is logged in
  -    subscribed - Boolean, true if user is subscribed to this collection
  -    admin_button - Boolean, show admin 'edit' button
  -    editor_button - Boolean, show collection editor (edit submitters, item mapping) buttons
  -    show.items - Boolean, show item list
  -    browse.info - BrowseInfo, item list
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="org.dspace.app.webui.components.RecentSubmissions" %>
<%@ page import="org.dspace.app.webui.components.MostDownloaded" %>

<%@ page import="org.dspace.app.webui.servlet.admin.EditCommunitiesServlet" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.browse.BrowseIndex" %>
<%@ page import="org.dspace.browse.BrowseInfo" %>
<%@ page import="org.dspace.browse.ItemCounter"%>
<%@ page import="org.dspace.content.*"%>
<%@ page import="org.dspace.core.ConfigurationManager"%>
<%@ page import="org.dspace.core.Context" %>
<%@ page import="org.dspace.eperson.Group"     %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="java.net.URLEncoder" %>

<%
    // Retrieve attributes
    Collection collection = (Collection) request.getAttribute("collection");
    Community  community  = (Community) request.getAttribute("community");
    Group      submitters = (Group) request.getAttribute("submitters");

    RecentSubmissions rs = (RecentSubmissions) request.getAttribute("recently.submitted");
    MostDownloaded mostdownloaded = (MostDownloaded) request.getAttribute("most.downloaded");
    
    boolean loggedIn =
        ((Boolean) request.getAttribute("logged.in")).booleanValue();
    boolean subscribed =
        ((Boolean) request.getAttribute("subscribed")).booleanValue();
    Boolean admin_b = (Boolean)request.getAttribute("admin_button");
    boolean admin_button = (admin_b == null ? false : admin_b.booleanValue());

    Boolean editor_b      = (Boolean)request.getAttribute("editor_button");
    boolean editor_button = (editor_b == null ? false : editor_b.booleanValue());

    Boolean submit_b      = (Boolean)request.getAttribute("can_submit_button");
    boolean submit_button = (submit_b == null ? false : submit_b.booleanValue());

  // get the browse indices
    BrowseIndex[] bis = BrowseIndex.getBrowseIndices();

    // Put the metadata values into guaranteed non-null variables
    String name = collection.getMetadata("name");
    String intro = collection.getMetadata("introductory_text");
    if (intro == null)
    {
        intro = "";
    }
    String copyright = collection.getMetadata("copyright_text");
    if (copyright == null)
    {
        copyright = "";
    }
    String sidebar = collection.getMetadata("side_bar_text");
    if(sidebar == null)
    {
        sidebar = "";
    }

    String communityName = community.getMetadata("name");
    String communityLink = "/handle/" + community.getHandle();

    Bitstream logo = collection.getLogo();
    
    boolean feedEnabled = ConfigurationManager.getBooleanProperty("webui.feed.enable");
    String feedData = "NONE";
    if (feedEnabled)
    {
        feedData = "coll:" + ConfigurationManager.getProperty("webui.feed.formats");
    }
    
    ItemCounter ic = new ItemCounter(UIUtil.obtainContext(request));

    Boolean showItems = (Boolean)request.getAttribute("show.items");
    boolean show_items = showItems != null ? showItems.booleanValue() : false;
%>

<%@page import="org.dspace.app.webui.servlet.MyDSpaceServlet"%>
<dspace:layout locbar="commLink" title="<%= name %>" feedData="<%= feedData %>">

  <header class="page-title-area">
    <%  if (logo != null) { %>
      <div class="img-hold">
        <img class="img-responsive" alt="Logo" src="<%= request.getContextPath() %>/retrieve/<%= logo.getID() %>" />
      </div>
    <%  } %>
    <h2><%= name %></h2>
  </header>

<%
  if (StringUtils.isNotBlank(intro)) { %>
  <div class="description">
  <%= intro %>
</div>
<%  } %>

  <p class="copyrightText"> <%= copyright %></p>
  
  <%-- Browse --%>


  <%@ include file="discovery/static-tagcloud-facet.jsp" %>

  <section class="search-area">
  <form method="get" action="/jspui/simple-search" class="simplest-search">
    <div class="form-group-flex">
    <div class="input-hold">
      <input type="text" class="form-control" placeholder="Search titles, authors, keywords..." name="query" id="tequery">
    </div>
    <div class="button-hold">
      <button type="submit" class="btn btn-primary"><span class="glyphicon glyphicon-search"></span></button>
    </div>
    </div>
  </form>
  </section>
<section class="collectionlist">

<% if (show_items)
   {
    BrowseInfo bi = (BrowseInfo) request.getAttribute("browse.info");
    BrowseIndex bix = bi.getBrowseIndex();


    String bi_name_key = "browse.menu." + bi.getSortOption().getName();
    String so_name_key = "browse.order." + (bi.isAscending() ? "asc" : "desc");

    Integer rpp =  bi.getResultsPerPage();
    Integer sortedByNum =  bi.getSortOption().getNumber();
    String sortedBy = bi.getSortOption().getName();

    String order = (bi.isAscending() ? "asc" : "desc");


    // prepare the next and previous links
    String linkBase = request.getContextPath() + "/handle/" + collection.getHandle();
    
    String next = linkBase;
    String prev = linkBase;
    
    if (bi.hasNextPage())
    {
      next = next + "?offset=" + bi.getNextOffset() + "&rpp=" + rpp + "&value=" + sortedByNum + "&data-order=" + order;
    }
    
    if (bi.hasPrevPage())
    {
      prev = prev + "?offset=" + bi.getPrevOffset() + "&rpp=" + rpp + "&value=" + sortedByNum + "&data-order=" + order;
    }

    String titleAscSelected = ((sortedBy.equalsIgnoreCase("title") && (order.equalsIgnoreCase("asc"))) ? "selected=\"selected\"" : "");
    String titleDescSelected = ((sortedBy.equalsIgnoreCase("title") && (order.equalsIgnoreCase("desc")))  ? "selected=\"selected\"" : "");
    String dateIAscSelected = ((sortedBy.equalsIgnoreCase("dateissued") && (order.equalsIgnoreCase("asc"))) ? "selected=\"selected\"" : "");
     String dateIDescSelected = ((sortedBy.equalsIgnoreCase("dateissued") && (order.equalsIgnoreCase("desc")))  ? "selected=\"selected\"" : "");


%>

<div class="discovery-results-header">
  <%-- give us the top report on what we are looking at --%>
  <fmt:message var="bi_name" key="<%= bi_name_key %>"/>
  <fmt:message var="so_name" key="<%= so_name_key %>"/>
  <h3 class="browse_range resultsnum">
    <fmt:message key="jsp.collection-home.content.range">
      <fmt:param value="${bi_name}"/>
      <fmt:param value="${so_name}"/>
      <fmt:param value="<%= Integer.toString(bi.getStart()) %>"/>
      <fmt:param value="<%= Integer.toString(bi.getFinish()) %>"/>
      <fmt:param value="<%= Integer.toString(bi.getTotal()) %>"/>
    </fmt:message>
  </h3>

 <div class="discovery-pagination-controls">
  <form action="" method="get" id="results-sorting">
    <select name="rpp" class="form-control" id="rpp_select">
<%
         for (int i = 5; i <= 100 ; i += 5)
         {
           String selected = (i == rpp ? "selected=\"selected\"" : "");
%>
           <option value="<%= i %>" <%= selected %>><%= i %> per page</option>
<%
         }
%>
       </select> 


    <select id="sort_by" name="value" class="form-control">
    <option data-order="asc" value="1" <%= titleAscSelected %>>Title A-Z</option>
    <option data-order="desc" value="1" <%= titleDescSelected %>>Title Z-A</option>
    <option data-order="desc" value="2" <%= dateIDescSelected %>>Newest</option>
    <option data-order="asc" value="2" <%= dateIAscSelected %>>Oldest</option>
    
    </select>
    <input type="hidden" value="<%= order %>" name="data-order">
    <input style="display:none"  type="submit" name="submit_search" value="go">
  </form>
  </div>
</div>
<script type="text/javascript">
  var jQ = jQuery.noConflict();
  jQ(document).ready(function() {
  jQ("#sort_by").change(function(){
    var direction = jQ(this).find("option:selected").attr('data-order');
    var hiddenfield = jQ(this).closest('form').find('input[name=data-order]');
    hiddenfield.val(direction);
    jQ(this).closest('form').trigger('submit');
  });
  jQ("#rpp_select").change(function(){
     jQ(this).closest('form').trigger('submit');
  });
  });
</script> 

<div class ="discovery-result-results">
<%-- output the results using the browselist tag --%>
   <dspace:browselist browseInfo="<%= bi %>" emphcolumn="<%= bi.getSortOption().getMetadata() %>" />
  <%-- give us the bottom repaort on what we are looking at --%>
</div>

  <%--  do the bottom previous and next page links --%>
  <div class="prev-next-links">
<% 
    if (bi.hasPrevPage())
    {
%>
    <a href="<%= prev %>"><fmt:message key="browse.full.prev"/></a>&nbsp;
<%
    }

    if (bi.hasNextPage())
    {
%>
    &nbsp;<a href="<%= next %>"><fmt:message key="browse.full.next"/></a>
<%
    }
%>
  </div>
</section>
<%
   } // end of if (show_title)
%>

  <dspace:sidebar>
  <aside class="sidebar">

  <%  if (submit_button)
  { %>
  <div class = "panel panel-default ">
    <div class = "panel-heading">Submit Item</div>
    <div class = "panel-body">
     <form class="form-group" action="<%= request.getContextPath() %>/submit" method="post">
    <input type="hidden" name="collection" value="<%= collection.getID() %>" />
    <input class="btn btn-info col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.collection-home.submit.button"/>" />
    </form>
  </div>
  </div>
<%  } %>

   <%if (mostdownloaded != null && mostdownloaded.count() > 0) { %>

  <div class="panel panel-primary most-downloaded">
               <div class="panel-heading"><h1>Most downloaded</h1></div>
               <div class="panel-body">

              <%

              for (Item item : mostdownloaded.getMostDownloaded())
              {

              if(item.isPublic()||editor_button) {
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
                <h1><a href="<%= request.getContextPath() %>/handle/<%=item.getHandle() %>"><%= displayTitle %></a></h1>
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

    %>     </div>
        </div>

      <%} %>

  


<% if(admin_button || editor_button ) { %>
         <div class="panel panel-admin-tools">
         <div class="panel-heading"><fmt:message key="jsp.admintools"/>
          <span class="pull-right"><dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.collection-admin\")%>"><fmt:message key="jsp.adminhelp"/></dspace:popup></span>
         </div>
         <div class="panel-body">              
<% if( editor_button ) { %>
        <form method="post" action="<%=request.getContextPath()%>/tools/edit-communities">
          <input type="hidden" name="collection_id" value="<%= collection.getID() %>" />
          <input type="hidden" name="community_id" value="<%= community.getID() %>" />
          <input type="hidden" name="action" value="<%= EditCommunitiesServlet.START_EDIT_COLLECTION %>" />
          <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.general.edit.button"/>" />
        </form>
<% } %>

<% if( admin_button ) { %>
         <form method="post" action="<%=request.getContextPath()%>/tools/itemmap">
                   <input type="hidden" name="cid" value="<%= collection.getID() %>" />

               <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.collection-home.item.button"/>" />
                 </form>
         <form method="get" action="<%=request.getContextPath()%>/tools/batchimport">
          <input type="hidden" name="colId" value="<%= collection.getID() %>" />
      <input class="btn btn-default col-md-12" type="submit" value="Batch Import" />
        </form>
<% if(submitters != null) { %>
      <form method="get" action="<%=request.getContextPath()%>/tools/group-edit">
      <input type="hidden" name="group_id" value="<%=submitters.getID()%>" />
      <input class="btn btn-default col-md-12" type="submit" name="submit_edit" value="<fmt:message key="jsp.collection-home.editsub.button"/>" />
      </form>
<% } %>
<% if( editor_button || admin_button) { %>
         <form method="post" action="<%=request.getContextPath()%>/tools/metadataexport">
         <input type="hidden" name="handle" value="<%= collection.getHandle() %>" />
         <input class="btn btn-default col-md-12" type="submit" value="<fmt:message key="jsp.general.metadataexport.button"/>" />
         </form>
         <form method="get" action="<%=request.getContextPath()%>/tools/metadataimport">
         <input type="hidden" name="handle" value="<%= collection.getHandle() %>" />
         <input class="btn btn-default col-md-12" type="submit" value="Import metadata" />
         </form>
         </div>
<% } %>
         
<% } %>

<%  } %>

<%
  if (rs != null)
  {
%>
  <h3><fmt:message key="jsp.collection-home.recentsub"/></h3>
<%
  Item[] items = rs.getRecentSubmissions();
  for (int i = 0; i < items.length; i++)
  {
    Metadatum[] dcv = items[i].getMetadata("dc", "title", null, Item.ANY);
    String displayTitle = "Untitled";
    if (dcv != null)
    {
    if (dcv.length > 0)
    {
      displayTitle = dcv[0].value;
    }
    }
    %><p class="recentItem"><a href="<%= request.getContextPath() %>/handle/<%= items[i].getHandle() %>"><%= displayTitle %></a></p><%
  }
%>
  <p>&nbsp;</p>
<%      } %>

  <%= sidebar %>
  <%
    int discovery_panel_cols = 12;
    int discovery_facet_cols = 12;
  %>
  <%@ include file="discovery/static-sidebar-facet.jsp" %>






<div class = "panel panel-default ">
  <div class = "panel-heading">Email subscription</div>
  <div class = "panel-body">

    <form  method="get" action="">
<%  if (loggedIn && subscribed)
  { %>
        <small><fmt:message key="jsp.collection-home.subscribed"/> <a href="<%= request.getContextPath() %>/subscribe"><fmt:message key="jsp.collection-home.info"/></a></small>
        <input class="btn btn-sm btn-warning" type="submit" name="submit_unsubscribe" value="<fmt:message key="jsp.collection-home.unsub"/>" />
<%  } else { %>
       
          <!--<fmt:message key="jsp.collection-home.subscribe.msg"/>-->
        
       <p>Receive email updates when new material is added to this collection.</p>
    <input class="btn btn-info col-md-12" type="submit" name="submit_subscribe" value="<fmt:message key="jsp.collection-home.subscribe"/>" />
     
<%  }
%>
    </form></div>
</div>
</aside>
  </dspace:sidebar>

</dspace:layout>

