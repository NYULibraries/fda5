<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Form to upload a metadata files
--%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="java.util.List"            %>
<%@ page import="java.util.ArrayList"            %>
<%@ page import="org.dspace.content.Collection"            %>

<%

	List<String> inputTypes = (List<String>)request.getAttribute("input-types");
	List<Collection> collections = (List<Collection>)request.getAttribute("collections");
	String hasErrorS = (String)request.getAttribute("has-error");
	boolean hasError = (hasErrorS==null) ? false : (Boolean.parseBoolean((String)request.getAttribute("has-error")));
	
	String uploadId = (String)request.getAttribute("uploadId");
	
    String message = (String)request.getAttribute("message");
    
	List<String> otherCollections = new ArrayList<String>();
	if (request.getAttribute("otherCollections")!=null) {
		otherCollections = (List<String>)request.getAttribute("otherCollections");
	}
		
	String owningCollectionID = null;
	if (request.getAttribute("cid")!=null){
		owningCollectionID = (String)request.getAttribute("cid");
	}
	
	String selectedInputType = null;
	if (request.getAttribute("inputType")!=null){
		selectedInputType = (String)request.getAttribute("inputType");
	}
%>

<dspace:layout style="submission" titlekey="jsp.dspace-admin.batchimport.title"
               navbar="default"
               locbar="link"
               parentlink="/"
               nocache="true">

    <h1><fmt:message key="jsp.dspace-admin.batchimport.title"/></h1>

	<% if (uploadId != null) { %>
		<div style="color:red">-- <fmt:message key="jsp.dspace-admin.batchimport.resume.info"/> --</div>
		<br/>
	<% } %>
			
<%
	if (hasErrorS == null){
	
	}
	else if (hasError && message!=null){
%>
	<div class="alert alert-warning"><%= message %></div>
<%  
    }
	else if (hasError && message==null){
%>
		<div class="alert alert-warning"><fmt:message key="jsp.dspace-admin.batchmetadataimport.genericerror"/></div>
<%  
	}
	else {
%>
		<div class="batchimport-info alert alert-info">
			<fmt:message key="jsp.dspace-admin.batchimport.info.success">
				<fmt:param><%= request.getContextPath() %>/mydspace</fmt:param>
			</fmt:message>
		</div>
<%  
	}
%>

    <form method="post" action="<%= request.getContextPath() %>/tools/batchimport" enctype="multipart/form-data">
	
		<div class="form-group">
			<label for="inputType"><fmt:message key="jsp.dspace-admin.batchmetadataimport.selectinputfile"/></label>
	        <select class="form-control" name="inputType" id="import-type">
			<%
				String safuploadSelected = ("safupload".equals(selectedInputType)) ? "selected" : "";
				String safSelected = ("saf".equals(selectedInputType)) ? "selected" : "";
			%>
	        	<option <%= safuploadSelected %> value="safupload"><fmt:message key="jsp.dspace-admin.batchimport.saf.upload"/></option>
				<option <%= safSelected %> value="saf"><fmt:message key="jsp.dspace-admin.batchimport.saf.remote"/></option>
	      </select>
 		</div>
 		
		<% if (uploadId != null) { %>
			<input type="hidden" name=uploadId value="<%= uploadId %>"/>
		<% } %>
		
		<div class="form-group" id="input-url" style="display:none">
			<label for="collection"><fmt:message key="jsp.dspace-admin.batchmetadataimport.selecturl"/></label><br/>
			<input type="text" name="zipurl" class="form-control"/>
        </div>
        
        <div class="form-group" id="input-file">
			<label for="file"><fmt:message key="jsp.dspace-admin.batchmetadataimport.selectfile"/></label>
            <input class="form-control" type="file" size="40" name="file"/>
        </div>
 
       <% if (request.getAttribute("colId")!=null) { %>
       			<input type="hidden" name="colId" value="<%= request.getAttribute("colId") %>"/>
       		<% } %>
        
        <input class="btn btn-success" type="submit" name="submit" value="<fmt:message key="jsp.dspace-admin.general.upload"/>" />

    </form>
    
    <script>
	    $( "#import-type" ).change(function() {
	    	var index = $("#import-type").prop("selectedIndex");
	    	if (index == 1){
	    		$( "#input-file" ).hide();
	    		$( "#input-url" ).show();
	    		$( "#owning-collection-info" ).show();
	    		$( "#owning-collection-optional" ).show();
	    	}
	    	else {
	    		$( "#input-file" ).show();
	    		$( "#input-url" ).hide();
	    		$( "#owning-collection-info" ).hide();
	    		$( "#owning-collection-optional" ).hide();
	    	}
	    });
		
		$( "#owning-collection-select" ).change(function() {
	    	var index = $("#owning-collection-select").prop("selectedIndex");
	    	if (index == 0){
	    		$( "#other-collections-div" ).hide();
				$( "#other-collections-select > option" ).attr("selected",false);
	    	}
	    	else {
	    		$( "#other-collections-div" ).show();
	    	}
	    });
    </script>
    
    
</dspace:layout>