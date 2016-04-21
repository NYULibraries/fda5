<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Form to upload a csv metadata file
--%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%
    String message = (String)request.getAttribute("message");
    if (message == null)
    {
        message = "";
    }
    else
    {
        message = "<p><b>" + message + "</b></p>";
    }
    String handle = (String)request.getAttribute("handle");
%>

<dspace:layout style="submission" titlekey="jsp.dspace-admin.metadataimport.title"
               navbar="default"
               locbar="link"
               parentlink="/"
               nocache="true">

    <h1><fmt:message key="jsp.dspace-admin.metadataimport.title"/></h1>

    <form method="post" enctype="multipart/form-data" action="<%= request.getContextPath() %>/tools/metadataimport">

        <%= message %>

        <p align="center">
            <input class="form-control" type="file" size="40" name="file"/>
        </p>

            <input type="hidden" name="handle" value="<%= handle %>" />


       <p align="center">
            <input class="btn btn-default" type="submit" name="submit" value="<fmt:message key="jsp.dspace-admin.general.upload"/>" />
        </p>

    </form>
    
</dspace:layout>
