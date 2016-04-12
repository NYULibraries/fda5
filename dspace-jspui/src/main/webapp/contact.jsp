<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Contact page JSP
  -
  --%>


<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="javax.servlet.jsp.jstl.core.*" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="org.dspace.core.I18nUtil" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@page import="org.apache.commons.lang.StringUtils"%>


<dspace:layout locbar="noLink" titlekey="jsp.home.title" >

<div class="row">
<div class="info-page col-md-9">
<header class="page-title-area"><h2>Contact Information</h2></header>
<p><strong>For help</strong><br />please e-mail to <a href="mailto: archive.help@nyu.edu">archive.help@nyu.edu</a>.</p
</dspace:layout>