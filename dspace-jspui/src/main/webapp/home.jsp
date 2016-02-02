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
<%
    Community[] communities = (Community[]) request.getAttribute("communities");

    Map collectionMap = (Map) request.getAttribute("collections.map");
    Map subcommunityMap = (Map) request.getAttribute("subcommunities.map");
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
    
    ItemCounter ic = new ItemCounter(UIUtil.obtainContext(request));

    RecentSubmissions submissions = (RecentSubmissions) request.getAttribute("recent.submissions");
    MostDownloaded mostdownloaded = ( MostDownloaded) request.getAttribute("most.downloaded");
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
<dspace:layout locbar="noLink" titlekey="jsp.home.title" feedData="<%= feedData %>">

          <div class="row">
            <div class="col-md-8 ">
              <div class="brand">
             
                The Faculty Digital Archive (FDA) is a highly visible repository of NYU scholarship, allowing digital works—text, audio, video, data, and more—to be reliably shared and securely stored. Collections may be made freely available worldwide, offered to NYU only, or restricted to a specific group.</p>
                Full-time faculty may contribute their research—unpublished and, in many cases, published—in the FDA. Departments, centers, or institutes may use the FDA to distribute their working papers, technical reports, or other research material. <a href="http://www.nyu.edu/its/faculty/fda" class="readmore">Read more...</a></p>
              </div>

<section class="search-area">
  <form method="get" action="simple-search" class="simplest-search">
    <div class="form-group-flex">
      <div class="input-hold">
      <input type="text" class="form-control" placeholder="Search titles, authors, keywords..." name="query" id="tequery" ></div>
      <div class="button-hold">   <button type="submit" class="btn btn-primary"><span class="glyphicon glyphicon-search"></span></button></div>
    </div>
  </form>
 </section>


<div class="fda-tree">
<%
for (int i = 0; i < communities.length; i++)
        {%>
        <ul>
          <%  showCommunity(communities[i], out, request, ic, collectionMap, subcommunityMap);%>
        </ul>
        <% }
%>
                </div>
            </div>
            <div class="col-md-4">
              <div class="panel panel-primary homepagesearch">
                <div class="panel-heading">
                  <h1>Most Popular Items</h1></div>
                <div class="panel-body">
                <div class="row">
<%
if (mostdownloaded != null && mostdownloaded.count() > 0)
{
%>
        <div class="col-md-8">
        <div class="panel panel-primary">        

                    <%

                    for (Item item : mostdownloaded.getMostDownloaded())
                    {
                      if(item!=null) {
                        Metadatum[] dcv = item.getMetadata("dc", "title", null, Item.ANY);
                        String displayTitle = "Untitled";
                        if (dcv != null & dcv.length > 0)
                        {
                            displayTitle = dcv[0].value;
                        }
                        dcv = item.getMetadata("dc", "description", "abstract", Item.ANY);
                        String displayAbstract = "";
                        if (dcv != null & dcv.length > 0)
                        {
                            displayAbstract = dcv[0].value;
                        }
                %>
                    <div style="padding-bottom: 10px; min-height: 200px;" class="item">
                        <a href="<%= request.getContextPath() %>/handle/<%=item.getHandle() %>" class="btn"><%= displayTitle  %></a>
                        <p><%= displayAbstract %></p>
                      </div>
                    </div>
                  <%

                     }
                     }
                %>


     </div></div>
<%
}
%>

                </div>
              </div>
            </div> <!-- end col 4 -->
          </div> <!-- end col row  -->
     
</dspace:layout>
