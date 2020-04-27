<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Display item/collection/community statistics
  -
  - Attributes:
  -    statsVisits - bean containing name, data, column and row labels
  -    statsMonthlyVisits - bean containing name, data, column and row labels
  -    statsFileDownloads - bean containing name, data, column and row labels
  -    statsCountryVisits - bean containing name, data, column and row labels
  -    statsCityVisits - bean containing name, data, column and row labels
  -    isItem - boolean variable, returns true if the DSO is an Item
  -    objectName - String which contains object Name added by Kate to accomodate new page design
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%@page import="org.dspace.app.webui.servlet.MyDSpaceServlet"%>

<% Boolean isItem = (Boolean)request.getAttribute("isItem"); %>
<% String objectName = (String)request.getAttribute("objectName"); %>


<dspace:layout titlekey="jsp.statistics.title">

<h1 class="statsPageTitle"><span class="statisticsLabel"><fmt:message key="jsp.statistics.title"/></span>
    <span class="itemTitle"> <c:out value="${objectName}"/></span>
</h1>

<div class="statsTimePeriod">
	Usage since April 12, 2016
</div>

<div class="mainStats">
  <div class="statsGroup">
    <section class="statsSection statsSectionTotal">
      <h2><fmt:message key="jsp.statistics.heading.visits"/></h2>
      <table class="statsTable">
        <tr>
        <th><fmt:message key="jsp.statistics.heading.views"/></th>
        </tr>
        <c:choose>
                <c:when test="${statsVisits.matrix[0][0]>0}">
                <c:forEach items="${statsVisits.matrix}" var="row" varStatus="counter">
                <c:forEach items="${row}" var="cell" varStatus="rowcounter">
                <tr >
                  <td>
                    <c:out value="${cell}"/>
                  </td>
                </tr>
                </c:forEach>
                </c:forEach>
               </c:when>
        <c:otherwise>
               <tr >
                   <td> 0 </td>
               </tr>
        </c:otherwise>
        </c:choose>

      </table>
    </section>

    <% if(isItem) { %>

      <section class="statsSection statsSectionDownloads">
      <h2><fmt:message key="jsp.statistics.heading.filedownloads"/></h2>
      <table class="statsTable">
      <tr>
        <th>Filename</th>
        <th><fmt:message key="jsp.statistics.heading.views"/></th>
      </tr>
      <c:choose>
          <c:when test="${statsFileDownloads.matrix[0][0]>0}">
             <c:forEach items="${statsFileDownloads.matrix}" var="row" varStatus="counter">
             <c:forEach items="${row}" var="cell" varStatus="rowcounter">
                <tr >
                   <td>
                     <c:out value="${cell}"/>
                   </td>
                </tr>
             </c:forEach>
             </c:forEach>
          </c:when>
          <c:otherwise>
              <tr >
                  <td> 0 </td>
              </tr>
          </c:otherwise>
       </c:choose>
      </table>
      </section>
    <% } %>

  </div>

  <section class="statsSection statsSectionMonthlyVisits">
    <h2><fmt:message key="jsp.statistics.heading.monthlyvisits"/></h2>
    <table class="statsTable">
    <c:choose>
       <c:when test="${statsVisits.matrix[0][0]>0}">
         <tr>
         <c:forEach items="${statsMonthlyVisits.colLabels}" var="headerlabel" varStatus="counter">
          <th>
           <c:out value="${headerlabel}"/>
          </th>
        </c:forEach>
        </tr>

        <c:forEach items="${statsMonthlyVisits.matrix}" var="row" varStatus="counter">
         <tr >
         <c:forEach items="${row}" var="cell">
          <td>
           <c:out value="${cell}"/>
          </td>
         </c:forEach>
         </tr>
        </c:forEach>
       </c:when>
       <c:otherwise >
        <tr>
        <td>0</td>
        </tr>
       </c:otherwise >
    </c:choose >
       </table>
  </section>

  <div class="statsGroup">
    <section class="statsSection statsSectionCountryVisits">
      <h2><fmt:message key="jsp.statistics.heading.countryvisits"/></h2>
      <table class="statsTable">
        <c:choose>
        <c:when test="${statsCountryVisits.matrix[0][0]>0}">
        <tr>
        <th>Country</th>
        <th><fmt:message key="jsp.statistics.heading.views"/></th>
        </tr>
        <c:forEach items="${statsCountryVisits.matrix}" var="row" varStatus="counter">
        <c:forEach items="${row}" var="cell" varStatus="rowcounter">

        <tr >
        <td>
        <c:out value="${statsCountryVisits.colLabels[rowcounter.index]}"/>
        <td>
        <c:out value="${cell}"/>
        </tr>
        </td>
        </c:forEach>
        </c:forEach>
       </c:when>
        <c:otherwise >
        <tr>
        <td>0</td>
        </tr>
        </c:otherwise>
        </c:choose>
      </table>
    </section>

    <section class="statsSection statsSectionCityVisits">
    <h2><fmt:message key="jsp.statistics.heading.cityvisits"/></h2>
    <table class="statsTable">
    <c:choose>
            <c:when test="${statsCityVisits.matrix[0][0]>0}">
            <tr>
            <th>Country</th>
            <th><fmt:message key="jsp.statistics.heading.views"/></th>
            </tr>
            <c:forEach items="${statsCityVisits.matrix}" var="row" varStatus="counter">
            <c:forEach items="${row}" var="cell" varStatus="rowcounter">
            <tr >
            <td>
            <c:out value="${statsCityVisits.colLabels[rowcounter.index]}"/>
            <td>
            <c:out value="${cell}"/>
            </tr>
            </td>
            </c:forEach>
            </c:forEach>
           </c:when>
            <c:otherwise >
            <tr>
            <td>0</td>
            </tr>
            </c:otherwise>
            </c:choose>
    </table>
    </section>
  </div>
</div>
</dspace:layout>



