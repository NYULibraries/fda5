<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Home page JSP
  -
  - Attributes:
  -    communities - Community[] all communities in DSpace
  -    recent.submissions - RecetSubmissions
  --%>

<%@page import="org.dspace.content.Bitstream"%>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="java.io.File" %>
<%@ page import="java.util.Enumeration"%>
<%@ page import="java.util.Locale"%>
<%@ page import="javax.servlet.jsp.jstl.core.*" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="org.dspace.core.I18nUtil" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.app.webui.components.RecentSubmissions" %>
<%@ page import="org.dspace.app.webui.components.MostDownloaded" %>
<%@ page import="org.dspace.content.Community" %>
<%@ page import="org.dspace.content.Collection" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="org.dspace.core.Context" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.core.NewsManager" %>
<%@ page import="org.dspace.browse.ItemCounter" %>
<%@ page import="org.dspace.browse.ItemCountException" %>
<%@ page import="org.dspace.content.Metadatum" %>
<%@ page import="org.dspace.content.Item" %>
<%@ page import="java.util.Map" %>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.authorize.AuthorizeManager" %>
<%@ page import="org.dspace.authorize.ResourcePolicy" %>
<%@ page import="org.dspace.core.Constants" %>
<%
    Community[] communities = (Community[]) request.getAttribute("communities");

    Map collectionMap = (Map) request.getAttribute("collections.map");
    Map subcommunityMap = (Map) request.getAttribute("subcommunities.map");
    ArrayList<Collection> nyuOnly = (ArrayList<Collection>)  request.getAttribute("nyuOnly");
    Locale sessionLocale = UIUtil.getSessionLocale(request);
    Config.set(request.getSession(), Config.FMT_LOCALE, sessionLocale);
    String topNews = NewsManager.readNewsFile(LocaleSupport.getLocalizedMessage(pageContext, "news-top.html"));
    String sideNews = NewsManager.readNewsFile(LocaleSupport.getLocalizedMessage(pageContext, "news-side.html"));

    boolean feedEnabled = ConfigurationManager.getBooleanProperty("webui.feed.enable");
    String feedData = "NONE";
    if (feedEnabled)
    {
        feedData = "ALL:" + ConfigurationManager.getProperty("webui.feed.formats");
    }
    


    RecentSubmissions submissions = (RecentSubmissions) request.getAttribute("recent.submissions");
    MostDownloaded mostdownloaded = ( MostDownloaded) request.getAttribute("most.downloaded");
%>
<%! //we use the same function 2 times so probably we should convert it to jsp tag but we can change something here so will leave for now
 void showCommunity(Community c, JspWriter out, HttpServletRequest request, Map collectionMap, Map subcommunityMap, ArrayList<Collection> nyuOnly) throws ItemCountException, IOException, SQLException
 	{
 		 // Get the sub-communities in this community

           Community[] comms = (Community[]) subcommunityMap.get(c.getID());

          // Get the collections in this community
           Collection[] cols = (Collection[]) collectionMap.get(c.getID());
           if (subcommunityMap.containsKey(c.getID()) || collectionMap.containsKey(c.getID()) )
            {

                 out.println( "<li role=\"treeitem\" >" );
                 out.println( "<span  class=\"t1\"><a href=\"" + request.getContextPath() + "/handle/"
                                            + c.getHandle() + "\">" + c.getMetadata("name") + "</a></span>");
                 out.println( "<ul role=\"group\" style=\"display:none \">" );

                 if (comms != null && comms.length > 0)
                 {

                     for (int k = 0; k < comms.length; k++)
                     {
                         showCommunity(comms[k], out, request, collectionMap, subcommunityMap,nyuOnly);
                     }

                 }

                 if (cols != null && cols.length > 0)
                 {

                     for (int j = 0; j < cols.length; j++)
                     {
                           out.println("<li class=\"tree-collections-list\" role=\"treeitem\" >");
                           //String collName =  ( StringUtils.isNotBlank(cols[j].getMetadata("name"))  ? cols[j].getMetadata("name") : "Untitled" );
                           out.println("<span  class=\"t1 ct1\"><a href=\"" + request.getContextPath() + "/handle/" + cols[j].getHandle() + "\">"+ cols.length+ cols[j].getMetadata("name") +"</a></span>");
                           if (nyuOnly.contains(cols[j]))
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
<dspace:layout locbar="noLink" titlekey="jsp.home.title" feedData="<%= feedData %>">
          <div class="row">
            <div class="col-md-8 ">
              <div class="brand">
             <h1 class="sr-only" id="page-title">NYU Faculty Digital Archive Homepage</h1>
                <p>The Faculty Digital Archive (FDA) is a highly visible repository of NYU scholarship, allowing digital works—text, audio, video, data, and more—to be reliably shared and securely stored. Collections may be made freely available worldwide, offered to NYU only, or restricted to a specific group.</p>
                <p>Full-time faculty may contribute their research—unpublished and, in many cases, published—in the FDA. Departments, centers, or institutes may use the FDA to distribute their working papers, technical reports, or other research material. <a href="/about" class="readmore" aria-label="Read more about the NYU Faculty Digital Archive">Read more...</a></p>
              </div>

<section class="search-area" role="search">
  <h2 class="sr-only">Search the archive</h2>
  <form method="get" action="/simple-search" class="simplest-search">
    <div class="form-group-flex">
      <div class="input-hold">
      <input type="text" aria-label="search" class="form-control" placeholder="Search titles, authors, keywords..." name="query" id="tequery" ></div>
      <div class="button-hold">   <button type="submit" aria-label="submit" class="btn btn-primary"><span role="presentation" class="glyphicon glyphicon-search"></span></button></div>
    </div>
  </form>
 </section>

<h2>Communities and Collections</h2>
<div class="fda-tree">
<%
for (int i = 0; i < communities.length; i++)
        {%>
        <ul role="tree">
          <%  showCommunity(communities[i], out, request,  collectionMap, subcommunityMap, nyuOnly);%>
        </ul>
        <% }
%>
                </div>
            </div>

<%
if (mostdownloaded != null && mostdownloaded.count() > 0)
{
%>
       <section class="col-md-4 sidebar">
                     <div class="panel panel-primary most-downloaded">
                       <div class="panel-heading">
                        <h2 class="panel-title">Most downloaded</h2></div>
                       <div class="panel-body">

                    <%

                    for (Item item : mostdownloaded.getMostDownloaded())
                    {

                      if(item.isPublic()) {
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

%>     </div>
        </div>
            </section> <!-- end col 4 -->
          </div> <!-- end col row  -->
<% } %>
     
</dspace:layout>
 vc