<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>

<%--
  - Display the form to refine the simple-search and dispaly the results of the search
  -
  - Attributes to pass in:
  -
  -   scope            - pass in if the scope of the search was a community
  -                      or a collection
  -   scopes 		   - the list of available scopes where limit the search
  -   sortOptions	   - the list of available sort options
  -   availableFilters - the list of filters available to the user
  -
  -   query            - The original query
  -   queryArgs		   - The query configuration parameters (rpp, sort, etc.)
  -   appliedFilters   - The list of applied filters (user input or facet)
  -
  -   search.error     - a flag to say that an error has occurred
  -   spellcheck	   - the suggested spell check query (if any)
  -   qResults		   - the discovery results
  -   items            - the results.  An array of Items, most relevant first
  -   communities      - results, Community[]
  -   collections      - results, Collection[]
  -
  -   admin_button     - If the user is an admin
  --%>

<%@page import="org.dspace.discovery.configuration.DiscoverySearchFilterFacet"%>
<%@page import="org.dspace.app.webui.util.UIUtil"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.ArrayList"%>
<%@page import="org.dspace.discovery.DiscoverFacetField"%>
<%@page import="org.dspace.discovery.configuration.DiscoverySearchFilter"%>
<%@page import="org.dspace.discovery.DiscoverFilterQuery"%>
<%@page import="org.dspace.discovery.DiscoverQuery"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="java.util.Map"%>
<%@page import="org.dspace.discovery.DiscoverResult.FacetResult"%>
<%@page import="org.dspace.discovery.DiscoverResult"%>
<%@page import="org.dspace.content.DSpaceObject"%>
<%@page import="java.util.List"%>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"
    prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"
    prefix="c" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@ page import="java.net.URLEncoder"            %>
<%@ page import="org.dspace.content.Community"   %>
<%@ page import="org.dspace.content.Collection"  %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.content.Item"        %>
<%@ page import="org.dspace.search.QueryResults" %>
<%@ page import="org.dspace.sort.SortOption" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.Set" %>
<%
    // Get the attributes
    DSpaceObject scope = (DSpaceObject) request.getAttribute("scope" );
    String searchScope = scope!=null?scope.getHandle():"";
    List<DSpaceObject> scopes = (List<DSpaceObject>) request.getAttribute("scopes");
    List<String> sortOptions = (List<String>) request.getAttribute("sortOptions");

    String query = (String) request.getAttribute("query");
		if (query == null)
		{
	    query = "";
		}
    Boolean error_b = (Boolean)request.getAttribute("search.error");
    boolean error = (error_b == null ? false : error_b.booleanValue());
    
    DiscoverQuery qArgs = (DiscoverQuery) request.getAttribute("queryArgs");
    String sortedBy = qArgs.getSortField();
    String order = qArgs.getSortOrder().toString();
    String titleAscSelected = ((sortedBy.equalsIgnoreCase("dc.title_sort") && (order.equalsIgnoreCase("ASC"))) ? "selected=\"selected\"" : "");
    String titleDescSelected = ((sortedBy.equalsIgnoreCase("dc.title_sort") && (order.equalsIgnoreCase("DESC")))  ? "selected=\"selected\"" : "");
    String dateIAscSelected = ((sortedBy.equalsIgnoreCase("dc.date.issued_dt") && (order.equalsIgnoreCase("ASC"))) ? "selected=\"selected\"" : "");
    String dateIDescSelected = ((sortedBy.equalsIgnoreCase("dc.date.issued_dt") && (order.equalsIgnoreCase("DESC")))  ? "selected=\"selected\"" : "");
    String ascSelected = (SortOption.ASCENDING.equalsIgnoreCase(order)   ? "selected=\"selected\"" : "");
    String descSelected = (SortOption.DESCENDING.equalsIgnoreCase(order) ? "selected=\"selected\"" : "");
    String httpFilters ="";
		String spellCheckQuery = (String) request.getAttribute("spellcheck");
    List<DiscoverySearchFilter> availableFilters = (List<DiscoverySearchFilter>) request.getAttribute("availableFilters");
		List<String[]> appliedFilters = (List<String[]>) request.getAttribute("appliedFilters");
		List<String> appliedFilterQueries = (List<String>) request.getAttribute("appliedFilterQueries");
		if (appliedFilters != null && appliedFilters.size() >0 ) 
		{
	    int idx = 1;
	    for (String[] filter : appliedFilters)
	    {
	        httpFilters += "&amp;filter_field_"+idx+"="+URLEncoder.encode(filter[0],"UTF-8");
	        httpFilters += "&amp;filter_type_"+idx+"="+URLEncoder.encode(filter[1],"UTF-8");
	        httpFilters += "&amp;filter_value_"+idx+"="+URLEncoder.encode(filter[2],"UTF-8");
	        idx++;
	    }
		}
    int rpp          = qArgs.getMaxResults();
    int etAl         = ((Integer) request.getAttribute("etal")).intValue();

    String[] options = new String[]{"equals","contains","notequals","notcontains"};
    
    // Admin user or not
    Boolean admin_b = (Boolean)request.getAttribute("admin_button");
    boolean admin_button = (admin_b == null ? false : admin_b.booleanValue());
    String scopeHome="";
    String scopeName = "";
    //added by Kate to return to collection
    if(searchScope != "")
         {
           //normalize
           String site=UIUtil.normalizePath(request.getContextPath());
            scopeHome= site+"/handle/"+searchScope;
           scopeName = scope.getMetadata("name");
        }
%>
<c:set var="dspace.layout.head.last" scope="request">
<script type="text/javascript">
	var jQ = jQuery.noConflict();
	jQ(document).ready(function() {

		jQ("#addafilter-link").click(function(e) {
      //console.log("clicked");
      e.preventDefault();
      openstate = jQ(".discovery-search-filters").is(":visible");
      if (!openstate) {
        jQ(".discovery-query").addClass("open");
        jQ(".discovery-search-filters").slideDown("fast", function() {
         // console.log("1 animation done");

        });
      } else {
        jQ(".discovery-query").removeClass("open");
        jQ(".discovery-search-filters").slideUp("fast", function() {
          //console.log("2 animation done");

        });
      }
    });
		jQ("#sort_by").change(function(){
			var direction = jQ(this).find("option:selected").attr('data-order');
			var hiddenfield = jQ(this).closest('form').find('input[name=order]');
			hiddenfield.val(direction);
			jQ(this).closest('form').trigger('submit');
		});
    jQ("#rpp_select").change(function(){
       jQ(this).closest('form').trigger('submit');
		});


		jQ( "#spellCheckQuery").click(function(){
			jQ("#query").val(jQ(this).attr('data-spell'));
			jQ("#main-query-submit").click();
		});

		

		jQ( "#filterquery" )
			.autocomplete({
				source: function( request, response ) {
					jQ.ajax({
						url: "<%= request.getContextPath() %>/json/discovery/autocomplete?query=<%= URLEncoder.encode(query,"UTF-8")%><%= httpFilters.replaceAll("&amp;","&") %>",
						dataType: "json",
						cache: false,
						data: {
							auto_idx: jQ("#filtername").val(),
							auto_query: request.term,
							auto_sort: 'count',
							auto_type: jQ("#filtertype").val(),
							location: '<%= searchScope %>'	
						},
						success: function( data ) {
							response( jQ.map( data.autocomplete, function( item ) {
								var tmp_val = item.authorityKey;
								if (tmp_val == null || tmp_val == '')
								{
									tmp_val = item.displayedValue;
								}
								return {
									label: item.displayedValue + " (" + item.count + ")",
									value: tmp_val
								};
							}))			
						}
					})
				}
			});
	});
	function validateFilters() {
		return document.getElementById("filterquery").value.length > 0;
	}
</script>		
</c:set>

<dspace:layout titlekey="jsp.search.title"  locbar="Link" parenttitle="<%= scopeName %>" parentlink="<%=scopeHome %>" >

    <%-- <h1>Search Results</h1> --%>

<%-- <h2 class="search-page-title"><fmt:message key="jsp.search.title"/></h2> --%>




<div class="discovery-search-form panel panel-default">
    <%-- Controls for a repeat search --%>
	<section class="discovery-query panel-body">
    <form action="simple-search" method="get">
    	<div class="form-group-flex community-choose">
    		<div class="form-flex-item ">
        	<label for="tlocation"><fmt:message key="jsp.search.results.searchin"/></label></div>
         	<div class="form-flex-item community-choose">
         		<select name="location" id="tlocation" class="form-control">
<%
    if (scope == null)
    {
        // Scope of the search was all of DSpace.  The scope control will list
        // "all of DSpace" and the communities.
%>
                <%-- <option selected value="/">All of DSpace</option> --%>
                <option selected="selected" value="/"><fmt:message key="jsp.general.genericScope"/></option>
<%  }
    else
    {
%>
									<option value="/"><fmt:message key="jsp.general.genericScope"/></option>
<%  }      
    for (DSpaceObject dso : scopes)
    {
%>
                  <option value="<%= dso.getHandle() %>" <%=dso.getHandle().equals(searchScope)?"selected=\"selected\"":"" %>>
                                	<%= dso.getName() %></option>
<%
    }
%>              </select></div></div>

			<div class="form-group-flex keyword-contain-group">
      		<div class="form-flex-item"><label for="query"><fmt:message key="jsp.search.results.searchfor"/></label></div>
     			<div class="form-flex-item keyword-contain"><input type="text"  id="query" class="form-control" name="query" value="<%= (query==null ? "" : StringEscapeUtils.escapeHtml(query)) %>"/></div>
      	                
			</div>  

	
	

<% if (appliedFilters.size() > 0 ) { %>                                

		<%
			int idx = 1;
			for (String[] filter : appliedFilters)
			{
			    boolean found = false;
			    %>

			<div class="form-group-flex  filter-group">
			<div class="form-flex-item flabel" >	
				<% if (idx == 1 ) { %>  
				<label>where </label>  
				<%  } else { %>  
				<label>and </label> 
					<%  }  %>  
				</div>
				<div class="form-flex-item fname" >	
			    <select id="filter_field_<%=idx %>" name="filter_field_<%=idx %>" class="form-control">
				<%
					for (DiscoverySearchFilter searchFilter : availableFilters)
					{
					    String fkey = "jsp.search.filter."+searchFilter.getIndexFieldName();
					    %><option value="<%= searchFilter.getIndexFieldName() %>"<% 
					            if (filter[0].equals(searchFilter.getIndexFieldName()))
					            {
					                %> selected="selected"<%
					                found = true;
					            }
					            %>><fmt:message key="<%= fkey %>"/></option><%
					}
					if (!found)
					{
					    String fkey = "jsp.search.filter."+filter[0];
					    %><option value="<%= filter[0] %>" selected="selected"><fmt:message key="<%= fkey %>"/></option><%
					}
				%>
				</select></div>
				<div class="form-flex-item ftype" >	
				<select id="filter_type_<%=idx %>" name="filter_type_<%=idx %>" class="form-control">
				<%
					for (String opt : options)
					{
					    String fkey = "jsp.search.filter.op."+opt;
					    %><option value="<%= opt %>"<%= opt.equals(filter[1])?" selected=\"selected\"":"" %>><fmt:message key="<%= fkey %>"/></option><%
					}
				%>
				</select></div>
				<div class="form-flex-item fvalue" >	
				<input type="text" id="filter_value_<%=idx %>" name="filter_value_<%=idx %>" value="<%= StringEscapeUtils.escapeHtml(filter[2]) %>"  class="form-control" /></div>
				<div class="form-flex-item fbutton" >	
				<input class="btn btn-default" type="submit" id="submit_filter_remove_<%=idx %>" name="submit_filter_remove_<%=idx %>" value="X" /></div>
			
</div>
				<%
				idx++;
			}
		%>    
	
<% } %>

  	<div class="submit-contain">
      			<button id="main-query-submit" aria-label="submit" type="submit" class="btn btn-primary"><span class="glyphicon glyphicon-search"></span></button>
						<input type="hidden" value="<%= rpp %>" name="rpp" />
						<input type="hidden" value="<%= sortedBy %>" name="sort_by" />
						<input type="hidden" value="<%= order %>" name="order" />
		</div>

					<% if (StringUtils.isNotBlank(spellCheckQuery)) {%>
						<p class="lead"><fmt:message key="jsp.search.didyoumean"><fmt:param><a id="spellCheckQuery" data-spell="<%= StringEscapeUtils.escapeHtml(spellCheckQuery) %>" href="#"><%= spellCheckQuery %></a></fmt:param></fmt:message></p>
					<% } %>  
					
		</form>



		<a id="addafilter-link" class="interface-link" href="#">+ Add a filter</a>
		</section>
<% if (availableFilters.size() > 0) { %>
		<div class="discovery-search-filters panel-body">
			<form action="simple-search" method="get">
				<div class="form-group-flex filter-group">
			  	<div class="form-flex-item flabel">
            <label>Where</label>
        	</div>
        	<div class="form-flex-item fname">
						<input type="hidden" value="<%= StringEscapeUtils.escapeHtml(searchScope) %>" name="location" />
						<input type="hidden" value="<%= StringEscapeUtils.escapeHtml(query) %>" name="query" />
		<% if (appliedFilterQueries.size() > 0 ) { 
				int idx = 1;
				for (String[] filter : appliedFilters)
				{
				    boolean found = false;
				    %>
				  <input type="hidden" id="filter_field_<%=idx %>" name="filter_field_<%=idx %>" value="<%= filter[0] %>" />
					<input type="hidden" id="filter_type_<%=idx %>" name="filter_type_<%=idx %>" value="<%= filter[1] %>" />
					<input type="hidden" id="filter_value_<%=idx %>" name="filter_value_<%=idx %>" value="<%= StringEscapeUtils.escapeHtml(filter[2]) %>" />
					<%
					idx++;
				}
		} %>
		<select id="filtername" name="filtername" class="form-control fname">
		<%
			for (DiscoverySearchFilter searchFilter : availableFilters)
			{
			    String fkey = "jsp.search.filter."+searchFilter.getIndexFieldName();
			    %><option value="<%= searchFilter.getIndexFieldName() %>"><fmt:message key="<%= fkey %>"/></option><%
			}
		%>
		</select> 
		</div>
    <div class="form-flex-item  ftype">
			<select id="filtertype" name="filtertype" class="form-control ftype">
		<%
			for (String opt : options)
			{
			    String fkey = "jsp.search.filter.op."+opt;
			    %><option value="<%= opt %>"><fmt:message key="<%= fkey %>"/></option><%
			}
		%>
		</select>
		</div>
    <div class="form-flex-item fvalue">
		<input type="text" id="filterquery" name="filterquery" class="form-control" 	required="required" />
		<input type="hidden" value="<%= rpp %>" name="rpp" />
		<input type="hidden" value="<%= sortedBy %>" name="sort_by" />
		<input type="hidden" value="<%= order %>" name="order" /></div>
		 <div class="form-flex-item fbutton">
		<input class="btn btn-default" type="submit" value="<fmt:message key="jsp.search.filter.add"/>" onclick="return validateFilters()" />
		</div></div>
		</form>
</div> <!-- end panel body -->
	  
<% } %>
        <%-- Include a component for modifying sort by, order, results per page, and et-al limit --%>
   
</div>   <!-- end discovery search panel -->


<% 

DiscoverResult qResults = (DiscoverResult)request.getAttribute("queryresults");
Item      [] items       = (Item[]      )request.getAttribute("items");
Community [] communities = (Community[] )request.getAttribute("communities");
Collection[] collections = (Collection[])request.getAttribute("collections");

if( error )
{
 %>
	<p align="center" class="submitFormWarn">
		<fmt:message key="jsp.search.error.discovery" />
	</p>
	<%
}
else if( qResults != null && qResults.getTotalSearchResults() == 0 )
{
 %>
    <%-- <p align="center">Search produced no results.</p> --%>
    <p align="center"><fmt:message key="jsp.search.general.noresults"/></p>
<%
}
else if( qResults != null)
{
    long pageTotal   = ((Long)request.getAttribute("pagetotal"  )).longValue();
    long pageCurrent = ((Long)request.getAttribute("pagecurrent")).longValue();
    long pageLast    = ((Long)request.getAttribute("pagelast"   )).longValue();
    long pageFirst   = ((Long)request.getAttribute("pagefirst"  )).longValue();

    // create the URLs accessing the previous and next search result pages
    String baseURL =  request.getContextPath()
                    + (searchScope != "" ? "/handle/" + searchScope : "")
                    + "/simple-search?query="
                    + URLEncoder.encode(query,"UTF-8")
                    + httpFilters
                    + "&amp;sort_by=" + sortedBy
                    + "&amp;order=" + order
                    + "&amp;rpp=" + rpp
                    + "&amp;etal=" + etAl
                    + "&amp;start=";
         if(searchScope != "")
     {
       scopeHome= request.getContextPath()+"/handle/"+searchScope;
       scopeName = scope.getMetadata("name");
    }

    String nextURL = baseURL;
    String firstURL = baseURL;
    String lastURL = baseURL;

    String prevURL = baseURL
            + (pageCurrent-2) * qResults.getMaxResults();

    nextURL = nextURL
            + (pageCurrent) * qResults.getMaxResults();
    
    firstURL = firstURL +"0";
    lastURL = lastURL + (pageTotal-1) * qResults.getMaxResults();


%>
 <div class="discovery-results-header">
<%
	long lastHint = qResults.getStart()+qResults.getMaxResults() <= qResults.getTotalSearchResults()?
	        qResults.getStart()+qResults.getMaxResults():qResults.getTotalSearchResults();
%>
    <%-- <p>Results <//%=qResults.getStart()+1%>-<//%=qResults.getStart()+qResults.getHitHandles().size()%> of --%>
	<h1 class="resultsnum h3"><fmt:message key="jsp.search.results.results">

        <fmt:param><%=qResults.getStart()+1%></fmt:param> 
        <fmt:param><%=lastHint%></fmt:param>
        <fmt:param><%=qResults.getTotalSearchResults()%></fmt:param>
      <fmt:param><%=(float) qResults.getSearchTime() / 1000%></fmt:param>
    </fmt:message></h1>
<!-- give a content to the div -->
	

 <div class="discovery-pagination-controls">


   <form action="simple-search" method="get" id="results-sorting">
   <input type="hidden" value="<%= StringEscapeUtils.escapeHtml(searchScope) %>" name="location" />
   <input type="hidden" value="<%= StringEscapeUtils.escapeHtml(query) %>" name="query" />
	<% if (appliedFilterQueries.size() > 0 ) { 
				int idx = 1;
				for (String[] filter : appliedFilters)
				{
				    boolean found = false;
				    %>
				    <input type="hidden" id="filter_field_<%=idx %>" name="filter_field_<%=idx %>" value="<%= filter[0] %>" />
					<input type="hidden" id="filter_type_<%=idx %>" name="filter_type_<%=idx %>" value="<%= filter[1] %>" />
					<input type="hidden" id="filter_value_<%=idx %>" name="filter_value_<%=idx %>" value="<%= StringEscapeUtils.escapeHtml(filter[2]) %>" />
					<%
					idx++;
				}
	} %>	
		
           <select name="rpp" class="form-control" id="rpp_select" aria-label="Results Per Page">
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
          
<%
           if (sortOptions.size() > 0)
           {
%>
            <!--   <label for="sort_by">   sorted by <fmt:message key="search.results.sort-by"/></label> -->
         
							<select name="sort_by" id="sort_by" class="form-control" aria-label="Sorting">
                                                                  <% if((scope==null)||(ConfigurationManager.getProperty("webui.collection.home.specialsort."+scope.getID())==null)) { %>    
									<option value="score"><fmt:message key="search.sort-by.relevance"/></option>
                                                                  <% } %>
									<option data-order="ASC" value="dc.title_sort" <%= titleAscSelected %>>Title A-Z</option>
									<option data-order="DESC" value="dc.title_sort" <%= titleDescSelected %>>Title Z-A</option>
 									<option data-order="DESC" value="dc.date.issued_dt" <%=dateIDescSelected%>  >Newest</option>
 									<option data-order="ASC" value="dc.date.issued_dt" <%=dateIAscSelected%>>Oldest</option>
							</select>
<%
           }


%>
          <input type="hidden" value="<%= order %>" name="order" />
       
           <input style="display:none" class="btn btn-default" type="submit" name="submit_search" value="<fmt:message key="search.update" />" />

<%
    if (admin_button)
    {
        %><input type="submit" class="btn btn-default" name="submit_export_metadata" value="<fmt:message key="jsp.general.metadataexport.button"/>" /><%
    }
%>
</form>
   </div></div>



 
<div class="discovery-result-results">
<% if (communities.length > 0 ) { %>
   <div class="community-results">
    <h3><fmt:message key="jsp.search.results.comhits"/></h3>
    <dspace:communitylist  communities="<%= communities %>" />
  </div>
<%  } %>
	

<% if (collections.length > 0 ) { %>
    <div class="collection-results">
    <h3><fmt:message key="jsp.search.results.colhits"/></h3>
    <dspace:collectionlist collections="<%= collections %>" />
   
  </div>
<% } %>

<% if (items.length > 0) { %>
    <div class="item-results">
    <% if ((communities.length > 0) || (collections.length > 0 ) ) { %>
    <h3><fmt:message key="jsp.search.results.itemhits"/></h3>
    <% } %>
    <% if(ConfigurationManager.getProperty("webui.collectionhome.browse."+searchScope)!=null) { %>
    <dspace:itemlist items="<%= items %>" authorLimit="<%= etAl %>" linkToEdit="true" />
    <% } else { %>
      <dspace:itemlist items="<%= items %>" authorLimit="<%= etAl %>" />
    <% } %>
    </div>
<% } %>
</div>
   

<%-- show again the navigation info/links --%>
<div class="discovery-result-pagination row container">

    <%-- <p align="center">Results <//%=qResults.getStart()+1%>-<//%=qResults.getStart()+qResults.getHitHandles().size()%> of --%>
<%
if (pageTotal > 1) { %>
  

<div class="text-center">
    <ul class="pagination ">
<%
if (pageFirst != pageCurrent)
{
    %><li><a href="<%= prevURL %>"><fmt:message key="jsp.search.general.previous" /></a></li><%
}
else
{
    %><li class="disabled"><span><fmt:message key="jsp.search.general.previous" /></span></li><%
}    

if (pageFirst != 1)
{
    %><li><a href="<%= firstURL %>">1</a></li><li class="disabled"><span>...<span></li><%
}

for( long q = pageFirst; q <= pageLast; q++ )
{
    String myLink = "<li><a href=\""
                    + baseURL;


    if( q == pageCurrent )
    {
        myLink = "<li class=\"active\"><span>" + q + "</span></li>";
    }
    else
    {
        myLink = myLink
            + (q-1) * qResults.getMaxResults()
            + "\">"
            + q
            + "</a></li>";
    }
%>

<%= myLink %>

<%
}

if (pageTotal > pageLast)
{
    %><li class="disabled"><span>...</span></li><li><a href="<%= lastURL %>"><%= pageTotal %></a></li><%
}
if (pageTotal > pageCurrent)
{
    %><li><a href="<%= nextURL %>"><fmt:message key="jsp.search.general.next" /></a></li><%
}
else
{
    %><li class="disabled"><span><fmt:message key="jsp.search.general.next" /></span></li><%
}
%>
</ul></div>

<% } %>

<!-- give a content to the div -->
</div>

<% } %>
<dspace:sidebar>
<aside class="sidebar">
<%
	boolean brefine = false;
	
	List<DiscoverySearchFilterFacet> facetsConf = (List<DiscoverySearchFilterFacet>) request.getAttribute("facetsConfig");
	Map<String, Boolean> showFacets = new HashMap<String, Boolean>();
		
	for (DiscoverySearchFilterFacet facetConf : facetsConf)
	{
	    String f = facetConf.getIndexFieldName();
	    List<FacetResult> facet = qResults.getFacetResult(f);
	    if (facet.size() == 0)
	    {
	        facet = qResults.getFacetResult(f+".year");
		    if (facet.size() == 0)
		    {
		        showFacets.put(f, false);
		        continue;
		    }
	    }
	    boolean showFacet = false;
	    for (FacetResult fvalue : facet)
	    { 
			if(!appliedFilterQueries.contains(f+"::"+fvalue.getFilterType()+"::"+fvalue.getAsFilterQuery()))
		    {
		        showFacet = true;
		        break;
		    }
	    }
	    showFacets.put(f, showFacet);
	    brefine = brefine || showFacet;
	}
	if (brefine) {
%>
<div class="panel">
<div class="panel-heading"><fmt:message key="jsp.search.facet.refine" /></div>
<div id="facets" class="facetBox panel-body">

<%
	for (DiscoverySearchFilterFacet facetConf : facetsConf)
	{
	    String f = facetConf.getIndexFieldName();
	    if (!showFacets.get(f))
	        continue;
	    List<FacetResult> facet = qResults.getFacetResult(f);
	    if (facet.size() == 0)
	    {
	        facet = qResults.getFacetResult(f+".year");
	    }
	    int limit = facetConf.getFacetLimit()+1;
	    
	    String fkey = "jsp.search.facet.refine."+f;
	    %><div id="facet_<%= f %>" class="facets">
	    <span class="facetName"><fmt:message key="<%= fkey %>" /></span>
	    <ul class="list-group"><%
	    int idx = 1;
	    int currFp = UIUtil.getIntParameter(request, f+"_page");
	    if (currFp < 0)
	    {
	        currFp = 0;
	    }
	    for (FacetResult fvalue : facet)
	    { 
	        if (idx != limit && !appliedFilterQueries.contains(f+"::"+fvalue.getFilterType()+"::"+fvalue.getAsFilterQuery()))
	        {
	        %><li class="list-group-item"><a href="<%= request.getContextPath()
                + (searchScope!=""?"/handle/"+searchScope:"")
                + "/simple-search?query="
                + URLEncoder.encode(query,"UTF-8")
                + "&amp;sort_by=" + sortedBy
                + "&amp;order=" + order
                + "&amp;rpp=" + rpp
                + httpFilters
                + "&amp;etal=" + etAl
                + "&amp;filtername="+URLEncoder.encode(f,"UTF-8")
                + "&amp;filterquery="+URLEncoder.encode(fvalue.getAsFilterQuery(),"UTF-8")
                + "&amp;filtertype="+URLEncoder.encode(fvalue.getFilterType(),"UTF-8") %>"
                title="<fmt:message key="jsp.search.facet.narrow"><fmt:param><%=fvalue.getDisplayedValue() %></fmt:param></fmt:message>">
                <span class="badge"><%= fvalue.getCount() %></span> 
                <%= StringUtils.abbreviate(fvalue.getDisplayedValue(),36) %></a></li><%
                idx++;
	        }
	        if (idx > limit)
	        {
	            break;
	        }
	    }
	    if (currFp > 0 || idx == limit)
	    {
	        %><li class="list-group-item list-group-nextlink">
	        <% if (currFp > 0) { %>
	        <a class="pull-left" href="<%= request.getContextPath()
	            + (searchScope!=""?"/handle/"+searchScope:"")
                + "/simple-search?query="
                + URLEncoder.encode(query,"UTF-8")
                + "&amp;sort_by=" + sortedBy
                + "&amp;order=" + order
                + "&amp;rpp=" + rpp
                + httpFilters
                + "&amp;etal=" + etAl  
                + "&amp;"+f+"_page="+(currFp-1) %>"><fmt:message key="jsp.search.facet.refine.previous" /></a>
            <% } %>
            <% if (idx == limit) { %>
            <a href="<%= request.getContextPath()
	            + (searchScope!=""?"/handle/"+searchScope:"")
                + "/simple-search?query="
                + URLEncoder.encode(query,"UTF-8")
                + "&amp;sort_by=" + sortedBy
                + "&amp;order=" + order
                + "&amp;rpp=" + rpp
                + httpFilters
                + "&amp;etal=" + etAl  
                + "&amp;"+f+"_page="+(currFp+1) %>"><span class="pull-right"><fmt:message key="jsp.search.facet.refine.next" /></span></a>
            <%
            }
            %></li><%
	    }
	    %></ul></div><%
	}

%>
	</div>
</div>
<% } %>
</aside>
</dspace:sidebar>
</dspace:layout>

