<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - License page JSP
  -
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
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.core.Constants" %>

<dspace:layout locbar="noLink" titlekey="jsp.license.title" >

<div class="container">
    <div class="row">
      <div class="info-page col-md-9">
        <header class="page-title-area"><h2>NYU Faculty Digital Archive Non-Exclusive Distribution License</h2>
        </header>
        <p>By granting a license at the time of submission, you assert that you either hold copyright to the content you submit, have permission of the copyright holder to distribute the content according to the terms of this license, or that the content is in the public domain, and that you grant to New York University (NYU) the non-exclusive right to reproduce, translate (as defined below), and distribute your submission (including the abstract) worldwide in electronic format.</p>
        <p>You agree that NYU may, without changing the content, translate the submission to any medium or format for the purpose of preservation. You also agree that NYU may keep more than one copy of this submission for purposes of security, back-up and preservation.
        </p>
        <p>You represent that your submission is in compliance with copyright guidance set forth in the <b>NYU Faculty Handbook</b> (<a href="https://www.nyu.edu/about/policies-guidelines-compliance/policies-and-guidelines/educational-and-research-uses-of-copyrighted-materials-policy-st.html">http://www.nyu.edu/about/policies-guidelines-compliance/policies-and-guidelines/educational-and-research-uses-of-copyrighted-materials-policy-st.html</a>), the <b>NYU Handbook for Use of Copyrighted Materials</b> (<a href="https://guides.nyu.edu/copyright">http://guides.nyu.edu/copyright</a>), and <b>ITS's Policy on Responsible Use of NYU Computers & Data</b> at (<a href="https://www.nyu.edu/its/policies/responsibleuse.html">http://www.nyu.edu/its/policies/responsibleuse.html</a>).
        </p>
        <p>NYU will clearly identify your name(s) as the author(s) or owner(s) of the submission, and will not make any alteration, other than as allowed by this license, to your submission.
        </p>
      </div>
    </div>
  </div>
</dspace:layout>
