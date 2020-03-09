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
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.core.NewsManager" %>
<%@ page import="java.util.Map" %>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.core.Constants" %>
<dspace:layout locbar="noLink" titlekey="jsp.home.help" feedData="<%= feedData %>">

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
