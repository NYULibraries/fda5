<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Show form allowing edit of collection metadata
  -
  - Attributes:
  -    item        - item to edit
  -    collections - collections the item is in, if any
  -    handle      - item's Handle, if any (String)
  -    dc.types    - MetadataField[] - all metadata fields in the registry
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"
    prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"
    prefix="c" %>

<%@ page import="java.util.Date" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>

<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="javax.servlet.jsp.PageContext" %>

<%@ page import="org.dspace.content.MetadataField" %>
<%@ page import="org.dspace.app.webui.servlet.admin.AuthorizeAdminServlet" %>
<%@ page import="org.dspace.app.webui.servlet.admin.EditItemServlet" %>
<%@ page import="org.dspace.content.Bitstream" %>
<%@ page import="org.dspace.content.BitstreamFormat" %>
<%@ page import="org.dspace.content.Bitstream.BitstreamComparator" %>
<%@ page import="org.dspace.content.Bundle" %>
<%@ page import="org.dspace.content.Collection" %>
<%@ page import="org.dspace.content.DCDate" %>
<%@ page import="org.dspace.content.Metadatum" %>
<%@ page import="org.dspace.content.Item" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.eperson.EPerson" %>
<%@ page import="org.dspace.core.Utils" %>
<%@ page import="org.dspace.app.util.*" %>
<%@ page import="org.dspace.content.authority.MetadataAuthorityManager" %>
<%@ page import="org.dspace.content.authority.ChoiceAuthorityManager" %>
<%@ page import="org.dspace.content.authority.Choices" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="org.dspace.core.I18nUtil" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.content.DCDate" %>
<%@ page import="org.dspace.content.DCLanguage" %>
<%@ page import="org.dspace.content.DCPersonName" %>
<%@ page import="org.dspace.content.DCSeriesNumber" %>

<%
    Item item = (Item) request.getAttribute("item");
    String handle = (String) request.getAttribute("handle");
    Collection[] collections = (Collection[]) request.getAttribute("collections");
    MetadataField[] dcTypes = (MetadataField[])  request.getAttribute("dc.types");
    HashMap metadataFields = (HashMap) request.getAttribute("metadataFields");
    request.setAttribute("LanguageSwitch", "hide");

    // Is anyone logged in?
    EPerson user = (EPerson) request.getAttribute("dspace.current.user");
    
    // Is the logged in user an admin of the item
    Boolean itemAdmin = (Boolean)request.getAttribute("admin_button");
    boolean isItemAdmin = (itemAdmin == null ? false : itemAdmin.booleanValue());
    
    Boolean policy = (Boolean)request.getAttribute("policy_button");
    boolean bPolicy = (policy == null ? false : policy.booleanValue());
    
    Boolean delete = (Boolean)request.getAttribute("delete_button");
    boolean bDelete = (delete == null ? false : delete.booleanValue());

    Boolean createBits = (Boolean)request.getAttribute("create_bitstream_button");
    boolean bCreateBits = (createBits == null ? false : createBits.booleanValue());

    Boolean removeBits = (Boolean)request.getAttribute("remove_bitstream_button");
    boolean bRemoveBits = (removeBits == null ? false : removeBits.booleanValue());

    Boolean ccLicense = (Boolean)request.getAttribute("cclicense_button");
    boolean bccLicense = (ccLicense == null ? false : ccLicense.booleanValue());
    
    Boolean withdraw = (Boolean)request.getAttribute("withdraw_button");
    boolean bWithdraw = (withdraw == null ? false : withdraw.booleanValue());
    
    Boolean reinstate = (Boolean)request.getAttribute("reinstate_button");
    boolean bReinstate = (reinstate == null ? false : reinstate.booleanValue());

    Boolean privating = (Boolean)request.getAttribute("privating_button");
    boolean bPrivating = (privating == null ? false : privating.booleanValue());
    
    Boolean publicize = (Boolean)request.getAttribute("publicize_button");
    boolean bPublicize = (publicize == null ? false : publicize.booleanValue());

    Boolean reOrderBitstreams = false; //(Boolean)request.getAttribute("reorder_bitstreams_button");
    boolean breOrderBitstreams = (reOrderBitstreams != null && reOrderBitstreams);
%>


   <%! // required by Controlled Vocabulary  add-on and authority addon
            String contextPath;

        // An unknown value of confidence for new, empty input fields,
        // so no icon appears yet.
        int unknownConfidence = Choices.CF_UNSET - 100;

        // This method is resposible for showing a link next to an input box
        // that pops up a window that to display a controlled vocabulary.
        // It should be called from the doOneBox and doTwoBox methods.
        // It must be extended to work with doTextArea.
        String doControlledVocabulary(String fieldName, PageContext pageContext, String vocabulary, boolean readonly)
        {
            String link = "";
            boolean enabled = ConfigurationManager.getBooleanProperty("webui.controlledvocabulary.enable");
            boolean useWithCurrentField = vocabulary != null && ! "".equals(vocabulary);

            if (enabled && useWithCurrentField && !readonly)
            {
                            // Deal with the issue of _0 being removed from fieldnames in the configurable submission system
                            if (fieldName.endsWith("_0"))
                            {
                                    fieldName = fieldName.substring(0, fieldName.length() - 2);
                            }
                            link =
                            "<a href='javascript:void(null);' onclick='javascript:popUp(\"" +
                                    contextPath + "/controlledvocabulary/controlledvocabulary.jsp?ID=" +
                                    fieldName + "&amp;vocabulary=" + vocabulary + "\")'>" +
                                            "<span class='controlledVocabularyLink'>" +
                                                    LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.controlledvocabulary") +
                                            "</span>" +
                            "</a>";
                    }

                    return link;
        }

        boolean hasVocabulary(String vocabulary)
        {
            boolean enabled = ConfigurationManager.getBooleanProperty("webui.controlledvocabulary.enable");
            boolean useWithCurrentField = vocabulary != null && !"".equals(vocabulary);
            boolean has = false;

            if (enabled && useWithCurrentField)
            {
                    has = true;
            }
            return has;
        }

        // is this field going to be rendered as Choice-driven <select>?
        boolean isSelectable(String fieldKey)
        {
            ChoiceAuthorityManager cam = ChoiceAuthorityManager.getManager();
            return (cam.isChoicesConfigured(fieldKey) &&
                "select".equals(cam.getPresentation(fieldKey)));
        }

        // Get the presentation type of the authority if any, null otherwise
        String getAuthorityType(PageContext pageContext, String fieldName, int collectionID)
        {
            MetadataAuthorityManager mam = MetadataAuthorityManager.getManager();
            ChoiceAuthorityManager cam = ChoiceAuthorityManager.getManager();
            StringBuffer sb = new StringBuffer();

            if (cam.isChoicesConfigured(fieldName))
            {
            	return cam.getPresentation(fieldName);
            }
            return null;
        }

        // Render the choice/authority controlled entry, or, if not indicated,
        // returns the given default inputBlock
        StringBuffer doAuthority(PageContext pageContext, String fieldName,
                int idx, int fieldCount, String fieldInput, String authorityValue,
                int confidenceValue, boolean isName, boolean repeatable,
                Metadatum[] dcvs, StringBuffer inputBlock, int collectionID)
        {
            MetadataAuthorityManager mam = MetadataAuthorityManager.getManager();
            ChoiceAuthorityManager cam = ChoiceAuthorityManager.getManager();
            StringBuffer sb = new StringBuffer();

            if (cam.isChoicesConfigured(fieldName))
            {
                boolean authority = mam.isAuthorityControlled(fieldName);
                boolean required = authority && mam.isAuthorityRequired(fieldName);
                boolean isSelect = "select".equals(cam.getPresentation(fieldName)) && !isName;

                // if this is not the only or last input, append index to input @names
                String authorityName = fieldName + "_authority";
                String confidenceName = fieldName + "_confidence";
                if (repeatable && !isSelect && idx != fieldCount-1)
                {
                    fieldInput += '_'+String.valueOf(idx+1);
                    authorityName += '_'+String.valueOf(idx+1);
                    confidenceName += '_'+String.valueOf(idx+1);
                }

                String confidenceSymbol = confidenceValue == unknownConfidence ? "blank" : Choices.getConfidenceText(confidenceValue).toLowerCase();
                String confIndID = fieldInput+"_confidence_indicator_id";

                if (authority)
                {
                    sb.append(" <img id=\""+confIndID+"\" title=\"")
                      .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.authority.confidence.description."+confidenceSymbol))
                      .append("\" class=\"pull-left ds-authority-confidence cf-")
                      // set confidence to cf-blank if authority is empty
                      .append(authorityValue==null||authorityValue.length()==0 ? "blank" : confidenceSymbol)
                      .append(" \" src=\"").append(contextPath).append("/image/confidence/invisible.gif\" />");


                    sb.append("<input type=\"text\" value=\"").append(authorityValue!=null?authorityValue:"")
                      .append("\" id=\"").append(authorityName)
                      .append("\" name=\"").append(authorityName).append("\" class=\"ds-authority-value form-control\"/>")
                      .append("<input type=\"hidden\" value=\"").append(confidenceSymbol)
                      .append("\" id=\"").append(confidenceName)
                      .append("\" name=\"").append(confidenceName)
                      .append("\" class=\"ds-authority-confidence-input\"/>");


                }

                // suggest is not supported for name input type
                if ("suggest".equals(cam.getPresentation(fieldName)) && !isName)
                {
                    if (inputBlock != null)
                        sb.insert(0, inputBlock);
                    sb.append("<span id=\"").append(fieldInput).append("_indicator\" style=\"display: none;\">")
                      .append("<img src=\"").append(contextPath).append("/image/authority/load-indicator.gif\" alt=\"Loading...\"/>")
                      .append("</span><div id=\"").append(fieldInput).append("_autocomplete\" class=\"autocomplete\" style=\"display: none;\"> </div>");

                    sb.append("<script type=\"text/javascript\">")
                      .append("var gigo = DSpaceSetupAutocomplete('edit_metadata',")
                      .append("{ metadataField: '").append(fieldName).append("', isClosed: '").append(required?"true":"false").append("', inputName: '")
                      .append(fieldInput).append("', authorityName: '").append(authorityName).append("', containerID: '")
                      .append(fieldInput).append("_autocomplete', indicatorID: '").append(fieldInput).append("_indicator', ")
                      .append("contextPath: '").append(contextPath)
                      .append("', confidenceName: '").append(confidenceName)
                      .append("', confidenceIndicatorID: '").append(confIndID)
                      .append("', collection: ").append(String.valueOf(collectionID))
                      .append(" }); </script>");
                }

                // put up a SELECT element containing all choices
                else if (isSelect)
                {
                    sb.append("<select class=\"form-control\" id=\"").append(fieldInput)
                       .append("_id\" name=\"").append(fieldInput)
                       .append("\" size=\"").append(String.valueOf(repeatable ? 6 : 1))
                       .append(repeatable ? "\" multiple>\n" :"\">\n");
                    Choices cs = cam.getMatches(fieldName, "", collectionID, 0, 0, null);
                    // prepend unselected empty value when nothing can be selected.
                    if (!repeatable && cs.defaultSelected < 0 && dcvs.length == 0)
                        sb.append("<option value=\"\"><!-- empty --></option>\n");
                    for (int i = 0; i < cs.values.length; ++i)
                    {
                        boolean selected = false;
                        for (Metadatum dcv : dcvs)
                        {
                            if (dcv.value.equals(cs.values[i].value))
                                selected = true;
                        }
                        sb.append("<option value=\"")
                          .append(cs.values[i].value.replaceAll("\"", "\\\""))
                          .append("\"")
                          .append(selected ? " selected>":">")
                          .append(cs.values[i].label).append("</option>\n");
                    }
                    sb.append("</select>\n");
                }

                  // use lookup for any other presentation style (i.e "select")
                else
                {
                    if (inputBlock != null)
                        sb.insert(0, inputBlock);
                    sb.append("<button class=\"btn btn-default col-md-1\" name=\"").append(fieldInput).append("_lookup\" ")
                      .append("onclick=\"javascript: return DSpaceChoiceLookup('")
                      .append(contextPath).append("/tools/lookup.jsp','")
                      .append(fieldName).append("','edit_metadata','")
                      .append(fieldInput).append("','").append(authorityName).append("','")
                      .append(confIndID).append("',")
                      .append(String.valueOf(collectionID)).append(",")
                      .append(String.valueOf(isName)).append(",false);\"")
                      .append(" title=\"")
                      .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.tools.lookup.lookup"))
                      .append("\"><span class=\"glyphicon glyphicon-search\"></span></button>");
                }

            }
            else if (inputBlock != null)
                sb = inputBlock;
            return sb;
        }

        void doPersonalName(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean required,
          boolean readonly, int fieldCountIncr, String label, PageContext pageContext, int collectionID)
          throws java.io.IOException
        {
       	  String authorityType = getAuthorityType(pageContext, fieldName, collectionID);

          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          int fieldCount = defaults.length + fieldCountIncr;
          StringBuffer headers = new StringBuffer();
          StringBuffer sb = new StringBuffer();
          org.dspace.content.DCPersonName dpn;
          String auth;
          int conf = 0;
          StringBuffer name = new StringBuffer();
          StringBuffer first = new StringBuffer();
          StringBuffer last = new StringBuffer();

          if (fieldCount == 0)
             fieldCount = 1;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">").append(label).append("</label>");
    	  sb.append("<div class=\"col-md-10\">");
          for (int i = 0; i < fieldCount; i++)
          {
        	 sb.append("<div class=\"row col-md-12\">");
        	 if ("lookup".equalsIgnoreCase(authorityType))
        	 {
        	 	sb.append("<div class=\"row col-md-10\">");
        	 }
             first.setLength(0);
             first.append(fieldName).append("_first");
             if (repeatable && i != fieldCount-1)
                first.append('_').append(i+1);

             last.setLength(0);
             last.append(fieldName).append("_last");
             if (repeatable && i != fieldCount-1)
                last.append('_').append(i+1);

             if (i < defaults.length)
             {
                dpn = new org.dspace.content.DCPersonName(defaults[i].value);
                auth = defaults[i].authority;
                conf = defaults[i].confidence;
             }
             else
             {
                dpn = new org.dspace.content.DCPersonName();
                auth = "";
                conf = unknownConfidence;
             }

             sb.append("<span class=\"col-md-5\"><input placeholder=\"")
               .append(Utils.addEntities(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.lastname")))
               .append("\" class=\"form-control\" type=\"text\" name=\"")
               .append(last.toString())
               .append("\" size=\"23\" ");
             if (readonly)
             {
                 sb.append("disabled=\"disabled\" ");
             }
             sb.append("value=\"")
               .append(dpn.getLastName().replaceAll("\"", "&quot;")) // Encode "
                       .append("\"/></span><span class=\"col-md-5\"><input placeholder=\"")
                       .append(Utils.addEntities(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.firstname")))
                       .append("\" class=\"form-control\" type=\"text\" name=\"")
                       .append(first.toString())
               .append("\" size=\"23\" ");
             if (readonly)
             {
                 sb.append("disabled=\"disabled\" ");
             }
             sb.append("value=\"")
               .append(dpn.getFirstNames()).append("\"/></span>");

             if ("lookup".equalsIgnoreCase(authorityType))
        	 {
                 sb.append(doAuthority(pageContext, fieldName, i, fieldCount, fieldName,
                         auth, conf, true, repeatable, defaults, null, collectionID));
                 sb.append("</div>");
        	 }


             if (repeatable && !readonly && i < defaults.length)
             {
                name.setLength(0);
                name.append(Utils.addEntities(dpn.getLastName()))
                    .append(' ')
                    .append(Utils.addEntities(dpn.getFirstNames()));
                // put a remove button next to filled in values
                sb.append("<button class=\"btn btn-danger pull-right col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_remove_")
                  .append(i)
                  .append("\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                  .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
             }
             else if (repeatable && !readonly && i == fieldCount - 1)
             {
                // put a 'more' button next to the last space
                sb.append("<button class=\"btn btn-default pull-right col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_add\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                  .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>");
             }
             sb.append("</div>");
          }
    	  sb.append("</div></div><br/>");
          out.write(sb.toString());
        }

        void doDate(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean required,
          boolean readonly, int fieldCountIncr, String label, PageContext pageContext, HttpServletRequest request)
          throws java.io.IOException
        {

          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          int fieldCount = defaults.length + fieldCountIncr;
          StringBuffer sb = new StringBuffer();
          org.dspace.content.DCDate dateIssued;

          if (fieldCount == 0)
             fieldCount = 1;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
            .append(label)
            .append("</label><div class=\"col-md-10\">");

          for (int i = 0; i < fieldCount; i++)
          {
             if (i < defaults.length)
                dateIssued = new org.dspace.content.DCDate(defaults[i].value);
             else
                dateIssued = new org.dspace.content.DCDate("");

             sb.append("<div class=\"row col-md-12\"><div class=\"input-group col-md-10\"><div class=\"row\">")
    			.append("<span class=\"input-group col-md-6\"><span class=\"input-group-addon\">")
             	.append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.month"))
                .append("</span><select class=\"form-control\" name=\"")
                .append(fieldName)
                .append("_month");
             if (repeatable && i>0)
             {
                sb.append('_').append(i);
             }
             if (readonly)
             {
                 sb.append("\" disabled=\"disabled");
             }
             sb.append("\"><option value=\"-1\"")
                .append((dateIssued.getMonth() == -1 ? " selected=\"selected\"" : ""))
    //          .append(">(No month)</option>");
                .append(">")
                .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.no_month"))
                .append("</option>");

             for (int j = 1; j < 13; j++)
             {
                sb.append("<option value=\"")
                  .append(j)
                  .append((dateIssued.getMonth() == j ? "\" selected=\"selected\"" : "\"" ))
                  .append(">")
                  .append(org.dspace.content.DCDate.getMonthName(j,I18nUtil.getSupportedLocale(request.getLocale())))
                  .append("</option>");
             }

             sb.append("</select></span>")
    	            .append("<span class=\"input-group col-md-2\"><span class=\"input-group-addon\">")
                    .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.day"))
                    .append("</span><input class=\"form-control\" type=\"text\" name=\"")
                .append(fieldName)
                .append("_day");
             if (repeatable && i>0)
                sb.append("_").append(i);
             if (readonly)
             {
                 sb.append("\" disabled=\"disabled");
             }
             sb.append("\" size=\"2\" maxlength=\"2\" value=\"")
                .append((dateIssued.getDay() > 0 ?
                         String.valueOf(dateIssued.getDay()) : "" ))
                    .append("\"/></span><span class=\"input-group col-md-4\"><span class=\"input-group-addon\">")
                    .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.year"))
                    .append("</span><input class=\"form-control\" type=\"text\" name=\"")
                .append(fieldName)
                .append("_year");
             if (repeatable && i>0)
                sb.append("_").append(i);
             if (readonly)
             {
                 sb.append("\" disabled=\"disabled");
             }
             sb.append("\" size=\"4\" maxlength=\"4\" value=\"")
                .append((dateIssued.getYear() > 0 ?
                     String.valueOf(dateIssued.getYear()) : "" ))
                .append("\"/></span></div></div>\n");

             if (repeatable && !readonly && i < defaults.length)
             {
                // put a remove button next to filled in values
                sb.append("<button class=\"btn btn-danger col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_remove_")
                  .append(i)
                  .append("\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                  .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
             }
             else if (repeatable && !readonly && i == fieldCount - 1)
             {
                // put a 'more' button next to the last space
                sb.append("<button class=\"btn btn-default col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_add\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                  .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>");
             }
             // put a blank if nothing else
             sb.append("</div>");
          }
          sb.append("</div></div><br/>");
          out.write(sb.toString());
        }
        //added by Kate
        void doSemester(javax.servlet.jsp.JspWriter out, Item item,
                  String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean required,
                  boolean readonly, int fieldCountIncr, String label, PageContext pageContext, HttpServletRequest request)
                  throws java.io.IOException
                {

                  Metadatum[] defaults = item.getMetadata(schema, "date", "issued", Item.ANY);
                  int fieldCount = defaults.length + fieldCountIncr;
                  StringBuffer sb = new StringBuffer();
                  org.dspace.content.DCDate dateIssued;

                  if (fieldCount == 0)
                     fieldCount = 1;

                  sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
                    .append(label)
                    .append("</label><div class=\"col-md-10\">");

                  for (int i = 0; i < fieldCount; i++)
                  {
                     if (i < defaults.length)
                        dateIssued = new org.dspace.content.DCDate(defaults[i].value);
                     else
                        dateIssued = new org.dspace.content.DCDate("");

                     sb.append("<div class=\"row col-md-12\"><div class=\"input-group col-md-10\"><div class=\"row\">")
            			.append("<span class=\"input-group col-md-6\"><span class=\"input-group-addon\">")
                     	.append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.semester"))
                        .append("</span><select class=\"form-control\" name=\"")
                        .append(fieldName)
                        .append("_semester");
                     if (repeatable && i>0)
                     {
                        sb.append('_').append(i);
                     }
                     if (readonly)
                     {
                         sb.append("\" disabled=\"disabled");
                     }
                     sb.append("\"><option value=\"-1\"")
                        .append((dateIssued.getMonth() == -1 ? " selected=\"selected\"" : ""))
                        .append(">")
                        .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.no_semester"))
                        .append("</option>");

                     String semester="";
                     String[] semester_options={"Fall","Winter","Spring","Summer"};
                     int month=dateIssued.getMonth();
                     switch (month) {
                                 case 9: semester="Fall";
                                     break;
                                 case 1: semester="Winter";
                                     break;
                                 case 3: semester="Spring";
                                     break;
                                 case 7: semester="Summer";
                                     break;
                             }

                      for (int j = 0; j < semester_options.length; j++)
                              {

                        sb.append("<option value=\"")
                          .append(semester_options[j])
                          .append((semester_options[j].equals(semester) ? "\" selected=\"selected\"" : "\"" ))
                          .append(">")
                          .append(semester_options[j])
                          .append("</option>");
                     }

                     sb.append("</select></span>")
            	            .append("<span class=\"input-group col-md-4\"><span class=\"input-group-addon\">")
                            .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.year"))
                            .append("</span><input class=\"form-control\" type=\"text\" name=\"")
                        .append(fieldName)
                        .append("_year");
                     if (repeatable && i>0)
                        sb.append("_").append(i);
                     if (readonly)
                     {
                         sb.append("\" disabled=\"disabled");
                     }
                     sb.append("\" size=\"4\" maxlength=\"4\" value=\"")
                        .append((dateIssued.getYear() > 0 ?
                             String.valueOf(dateIssued.getYear()) : "" ))
                        .append("\"/></span></div></div>\n");

                     if (repeatable && !readonly && i < defaults.length)
                     {
                        // put a remove button next to filled in values
                        sb.append("<button class=\"btn btn-danger col-md-2\" name=\"submit_")
                          .append(fieldName)
                          .append("_remove_")
                          .append(i)
                          .append("\" value=\"")
                          .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                          .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
                     }
                     else if (repeatable && !readonly && i == fieldCount - 1)
                     {
                        // put a 'more' button next to the last space
                        sb.append("<button class=\"btn btn-default col-md-2\" name=\"submit_")
                          .append(fieldName)
                          .append("_add\" value=\"")
                          .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                          .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>");
                     }
                     // put a blank if nothing else
                     sb.append("</div>");
                  }
                  sb.append("</div></div><br/>");
                  out.write(sb.toString());
                }



        void doSeriesNumber(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable,
          boolean required, boolean readonly, int fieldCountIncr, String label, PageContext pageContext)
          throws java.io.IOException
        {

          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          int fieldCount = defaults.length + fieldCountIncr;
          StringBuffer sb = new StringBuffer();
          org.dspace.content.DCSeriesNumber sn;
          StringBuffer headers = new StringBuffer();

          if (fieldCount == 0)
             fieldCount = 1;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
          	.append(label)
          	.append("</label><div class=\"col-md-10\">");

          for (int i = 0; i < fieldCount; i++)
          {
             if (i < defaults.length)
               sn = new org.dspace.content.DCSeriesNumber(defaults[i].value);
             else
               sn = new org.dspace.content.DCSeriesNumber();

             sb.append("<div class=\"row col-md-12\"><span class=\"col-md-5\"><input class=\"form-control\" type=\"text\" name=\"")
               .append(fieldName)
               .append("_series");
             if (repeatable && i!= fieldCount)
               sb.append("_").append(i+1);
             if (readonly)
             {
                 sb.append("\" disabled=\"disabled");
             }
             sb.append("\" placeholder=\"")
               .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.seriesname").replaceAll("\"", "&quot;"));
             sb.append("\" size=\"23\" value=\"")
               .append(sn.getSeries().replaceAll("\"", "&quot;"))
               .append("\"/></span><span class=\"col-md-5\"><input class=\"form-control\" type=\"text\" name=\"")
               .append(fieldName)
               .append("_number");
             if (repeatable && i!= fieldCount)
               sb.append("_").append(i+1);
             if (readonly)
             {
                 sb.append("\" disabled=\"disabled");
             }
             sb.append("\" placeholder=\"")
               .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.paperno").replaceAll("\"", "&quot;"));
             sb.append("\" size=\"23\" value=\"")
               .append(sn.getNumber().replaceAll("\"", "&quot;"))
               .append("\"/></span>\n");

             if (repeatable && !readonly && i < defaults.length)
             {
                // put a remove button next to filled in values
                sb.append("<button class=\"btn btn-danger col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_remove_")
                  .append(i)
                  .append("\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                  .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
             }
             else if (repeatable && !readonly && i == fieldCount - 1)
             {
                // put a 'more' button next to the last space
                sb.append("<button class=\"btn btn-default col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_add\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                  .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>");
             }

             // put a blank if nothing else
             sb.append("</div>");
          }
          sb.append("</div></div><br/>");

          out.write(sb.toString());
        }

        void doTextArea(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean required, boolean readonly,
          int fieldCountIncr, String label, PageContext pageContext, String vocabulary, boolean closedVocabulary, int collectionID)
          throws java.io.IOException
        {
          String authorityType = getAuthorityType(pageContext, fieldName, collectionID);
          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          int fieldCount = defaults.length + fieldCountIncr;
          StringBuffer sb = new StringBuffer();
          String val, auth;
          int conf = unknownConfidence;

          if (fieldCount == 0)
             fieldCount = 1;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
          	.append(label)
          	.append("</label><div class=\"col-md-10\">");

          for (int i = 0; i < fieldCount; i++)
          {
             if (i < defaults.length)
             {
               val = defaults[i].value;
                  auth = defaults[i].authority;
                  conf = defaults[i].confidence;
             }
             else
             {
               val = "";
                auth = "";
             }
             sb.append("<div class=\"row col-md-12\">\n");
             String fieldNameIdx = fieldName + ((repeatable && i != fieldCount-1)?"_" + (i+1):"");
             sb.append("<div class=\"col-md-10\">");
             if (authorityType != null)
             {
            	 sb.append("<div class=\"col-md-10\">");
             }
             sb.append("<textarea class=\"form-control\" name=\"").append(fieldNameIdx)
               .append("\" rows=\"4\" cols=\"45\" id=\"")
               .append(fieldNameIdx).append("_id\" ")
               .append((hasVocabulary(vocabulary)&&closedVocabulary)||readonly?" disabled=\"disabled\" ":"")
               .append(">")
               .append(val)
               .append("</textarea>")
               .append(doControlledVocabulary(fieldNameIdx, pageContext, vocabulary, readonly));
             if (authorityType != null)
             {
            	 sb.append("</div><div class=\"col-md-2\">");
    	         sb.append(doAuthority(pageContext, fieldName, i, fieldCount, fieldName,
                                auth, conf, false, repeatable,
                                defaults, null, collectionID));
    	         sb.append("</div>");
             }

             sb.append("</div>");


             if (repeatable && !readonly && i < defaults.length)
             {
                // put a remove button next to filled in values
                sb.append("<button class=\"btn btn-danger col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_remove_")
                  .append(i)
                  .append("\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                  .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
             }
             else if (repeatable && !readonly && i == fieldCount - 1)
             {
                // put a 'more' button next to the last space
                sb.append("<button class=\"btn btn-default col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_add\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                  .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>");
             }

             // put a blank if nothing else
             sb.append("</div>");
          }
          sb.append("</div></div><br/>");

          out.write(sb.toString());
        }

        void doOneBox(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean required, boolean readonly,
          int fieldCountIncr, String label, PageContext pageContext, String vocabulary, boolean closedVocabulary, int collectionID)
          throws java.io.IOException
        {
          String authorityType = getAuthorityType(pageContext, fieldName, collectionID);
          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          int fieldCount = defaults.length + fieldCountIncr;
          StringBuffer sb = new StringBuffer();
          String val, auth;
          int conf= 0;

          if (fieldCount == 0)
             fieldCount = 1;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
            .append(label)
            .append("</label>");
          sb.append("<div class=\"col-md-10\">");
          for (int i = 0; i < fieldCount; i++)
          {
               if (i < defaults.length)
               {
                 val = defaults[i].value.replaceAll("\"", "&quot;");
                 auth = defaults[i].authority;
                 conf = defaults[i].confidence;
               }
               else
               {
                 val = "";
                 auth = "";
                 conf= unknownConfidence;
               }

               sb.append("<div class=\"row col-md-12\">");
               String fieldNameIdx = fieldName + ((repeatable && i != fieldCount-1)?"_" + (i+1):"");

               sb.append("<div class=\"col-md-10\">");
               if (authorityType != null)
               {
            	   sb.append("<div class=\"row col-md-10\">");
               }
               sb.append("<input class=\"form-control\" type=\"text\" name=\"")
                 .append(fieldNameIdx)
                 .append("\" id=\"")
                 .append(fieldNameIdx).append("\" size=\"50\" value=\"")
                 .append(val +"\"")
                 .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
                 .append("/>")
    			 .append(doControlledVocabulary(fieldNameIdx, pageContext, vocabulary, readonly))
                 .append("</div>");

               if (authorityType != null)
               {
            	   sb.append("<div class=\"col-md-2\">");
    	           sb.append(doAuthority(pageContext, fieldName, i,  fieldCount,
                                  fieldName, auth, conf, false, repeatable,
                                  defaults, null, collectionID));
               	   sb.append("</div></div>");
               }

              if (repeatable && !readonly && i < defaults.length)
              {
                 // put a remove button next to filled in values
                 sb.append("<button class=\"btn btn-danger col-md-2\" name=\"submit_")
                   .append(fieldName)
                   .append("_remove_")
                   .append(i)
                   .append("\" value=\"")
                   .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                   .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
              }
              else if (repeatable && !readonly && i == fieldCount - 1)
              {
                 // put a 'more' button next to the last space
                 sb.append("<button class=\"btn btn-default col-md-2\" name=\"submit_")
                   .append(fieldName)
                   .append("_add\" value=\"")
                   .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                   .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>");
              }

              sb.append("</div>");
            }
          sb.append("</div>");
          sb.append("</div><br/>");

          out.write(sb.toString());
        }

        void doTwoBox(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean required, boolean readonly,
          int fieldCountIncr, String label, PageContext pageContext, String vocabulary, boolean closedVocabulary)
          throws java.io.IOException
        {
          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          int fieldCount = defaults.length + fieldCountIncr;
          StringBuffer sb = new StringBuffer();
          StringBuffer headers = new StringBuffer();

          String fieldParam = "";

          if (fieldCount == 0)
             fieldCount = 1;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
            .append(label)
            .append("</label>");
          sb.append("<div class=\"col-md-10\">");
          for (int i = 0; i < fieldCount; i++)
          {
         	 sb.append("<div class=\"row col-md-12\">");

             if(i != fieldCount)
             {
                 //param is field name and index, starting from 1 (e.g. myfield_2)
                 fieldParam = fieldName + "_" + (i+1);
             }
             else
             {
                 //param is just the field name
                 fieldParam = fieldName;
             }

             if (i < defaults.length)
             {
               sb.append("<span class=\"col-md-4\"><input class=\"form-control\" type=\"text\" name=\"")
                 .append(fieldParam)
                 .append("\" size=\"15\" value=\"")
                 .append(defaults[i].value.replaceAll("\"", "&quot;"))
                 .append("\"")
                 .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
                 .append("\" />");

               sb.append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly));
               sb.append("</span>");
              if (!readonly)
              {
                           sb.append("<button class=\"btn btn-danger col-md-2\" name=\"submit_")
                                 .append(fieldName)
                                 .append("_remove_")
                                 .append(i)
                                 .append("\" value=\"")
                                 .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove2"))
                                 .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
              }
              else {
            	  sb.append("<span class=\"col-md-2\">&nbsp;</span>");
              }
             }
             else
             {
               sb.append("<span class=\"col-md-4\"><input class=\"form-control\" type=\"text\" name=\"")
                 .append(fieldParam)
                 .append("\" size=\"15\"")
                 .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
                 .append("/>")
                 .append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly))
                 .append("</span>\n")
                 .append("<span class=\"col-md-2\">&nbsp;</span>");
             }

             i++;

             if(i != fieldCount)
                     {
                             //param is field name and index, starting from 1 (e.g. myfield_2)
                         fieldParam = fieldName + "_" + (i+1);
                     }
                     else
                     {
                             //param is just the field name
                             fieldParam = fieldName;
                     }

                     if (i < defaults.length)
                     {
                       sb.append("<span class=\"col-md-4\"><input class=\"form-control\" type=\"text\" name=\"")
                         .append(fieldParam)
                         .append("\" size=\"15\" value=\"")
                         .append(defaults[i].value.replaceAll("\"", "&quot;"))
                             .append("\"")
                             .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
                             .append("/>");
                       sb.append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly));
                       sb.append("</span>");
                       if (!readonly)
                       {
                                   sb.append(" <button class=\"btn btn-danger col-md-2\" name=\"submit_")
                                         .append(fieldName)
                                         .append("_remove_")
                                         .append(i)
                                         .append("\" value=\"")
                                         .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove2"))
                                         .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
                       }
                       else {
                     	  sb.append("<span class=\"col-md-2\">&nbsp;</span>");
                       }
                     }
                     else
                     {
                       sb.append("<span class=\"col-md-4\"><input class=\"form-control\" type=\"text\" name=\"")
                         .append(fieldParam)
                         .append("\" size=\"15\"")
                         .append((hasVocabulary(vocabulary)&&closedVocabulary)||readonly?" disabled=\"disabled\" ":"")
                         .append("/>")
                         .append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly))
            			 .append("</span>\n");
                       if (i+1 >= fieldCount && !readonly)
                       {
                         sb.append(" <button class=\"btn btn-default col-md-2\" name=\"submit_")
                           .append(fieldName)
                           .append("_add\" value=\"")
                           .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                           .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>\n");
                       }
                     }
           sb.append("</div>");
          }
          sb.append("</div></div><br/>");
          out.write(sb.toString());
        }



        void doQualdropValue(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, DCInputSet inputs, boolean repeatable, boolean required,
          boolean readonly, int fieldCountIncr, List qualMap, String label, PageContext pageContext)
          throws java.io.IOException
        {
          Metadatum[] unfiltered = item.getMetadata(schema, element, Item.ANY, Item.ANY);
          // filter out both unqualified and qualified values occurring elsewhere in inputs
          List<Metadatum> filtered = new ArrayList<Metadatum>();
          for (int i = 0; i < unfiltered.length; i++)
          {
              String unfilteredFieldName = unfiltered[i].element;
              if(unfiltered[i].qualifier != null && unfiltered[i].qualifier.length()>0)
                  unfilteredFieldName += "." + unfiltered[i].qualifier;

                  if ( ! inputs.isFieldPresent(unfilteredFieldName) )
                  {
                          filtered.add( unfiltered[i] );
                  }
          }
          Metadatum[] defaults = filtered.toArray(new Metadatum[0]);

          int fieldCount = defaults.length + fieldCountIncr;
          StringBuffer sb = new StringBuffer();
          String   q, v, currentQual, currentVal;

          if (fieldCount == 0)
             fieldCount = 1;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
          	.append(label)
          	.append("</label>");
          sb.append("<div class=\"col-md-10\">");
          for (int j = 0; j < fieldCount; j++)
          {

             if (j < defaults.length)
             {
                currentQual = defaults[j].qualifier;
                if(currentQual==null) currentQual="";
                currentVal = defaults[j].value;
             }
             else
             {
                currentQual = "";
                currentVal = "";
             }

             // do the dropdown box
             sb.append("<div class=\"row col-md-12\"><span class=\"input-group col-md-10\"><span class=\"input-group-addon\"><select name=\"")
               .append(fieldName)
               .append("_qualifier");
             if (repeatable && j!= fieldCount-1)
               sb.append("_").append(j+1);
             if (readonly)
             {
                 sb.append("\" disabled=\"disabled");
             }
             sb.append("\">");
             for (int i = 0; i < qualMap.size(); i+=2)
             {
               q = (String)qualMap.get(i);
               v = (String)qualMap.get(i+1);
               sb.append("<option")
                 .append((v.equals(currentQual) ? " selected=\"selected\" ": "" ))
                 .append(" value=\"")
                 .append(v)
                 .append("\">")
                 .append(q)
                 .append("</option>");
             }

             // do the input box
             sb.append("</select></span><input class=\"form-control\" type=\"text\" name=\"")
               .append(fieldName)
               .append("_value");
             if (repeatable && j!= fieldCount-1)
               sb.append("_").append(j+1);
             if (readonly)
             {
                 sb.append("\" disabled=\"disabled");
             }
             sb.append("\" size=\"34\" value=\"")
               .append(currentVal.replaceAll("\"", "&quot;"))
               .append("\"/></span>\n");

             if (repeatable && !readonly && j < defaults.length)
             {
                // put a remove button next to filled in values
                sb.append("<button class=\"btn btn-danger col-md-2\" name=\"submit_")
                  .append(fieldName)
                  .append("_remove_")
                  .append(j)
                  .append("\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                  .append("\"><span class=\"glyphicon glyphicon-trash\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove")+"</button>");
             }
             else if (repeatable && !readonly && j == fieldCount - 1)
             {
                // put a 'more' button next to the last space
                sb.append("<button class=\"btn btn-default col-md-2\" name=\"submit_")
                  .append(fieldName)
    //            .append("_add\" value=\"Add More\"/> </td></tr>");
                  .append("_add\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                  .append("\"><span class=\"glyphicon glyphicon-plus\"></span>&nbsp;&nbsp;"+LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add")+"</button>");
             }

             // put a blank if nothing else
           	 sb.append("</div>");
          }
          sb.append("</div></div><br/>");
          out.write(sb.toString());
        }

        void doDropDown(javax.servlet.jsp.JspWriter out, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable,
          boolean required, boolean readonly, List valueList, String label)
          throws java.io.IOException
        {
          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          StringBuffer sb = new StringBuffer();
          Iterator vals;
          String display, value;
          int j;

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
            .append(label)
            .append("</label>");

          sb.append("<span class=\"col-md-8\">")
            .append("<select class=\"form-control\" name=\"")
            .append(fieldName)
            .append("\"");
          if (repeatable)
            sb.append(" size=\"6\"  multiple=\"multiple\"");
          if (readonly)
          {
              sb.append(" disabled=\"disabled\"");
          }
          sb.append(">");

          for (int i = 0; i < valueList.size(); i += 2)
          {
             display = (String)valueList.get(i);
             value = (String)valueList.get(i+1);
             for (j = 0; j < defaults.length; j++)
             {
                 if (value.equals(defaults[j].value))
                     break;
             }
             sb.append("<option ")
               .append(j < defaults.length ? " selected=\"selected\" " : "")
               .append("value=\"")
               .append(value.replaceAll("\"", "&quot;"))
               .append("\">")
               .append(display)
               .append("</option>");
          }

          sb.append("</select></span></div><br/>");
          out.write(sb.toString());
        }

        void doChoiceSelect(javax.servlet.jsp.JspWriter out, PageContext pageContext, Item item,
          String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean required,
          boolean readonly, List valueList, String label, int collectionID)
          throws java.io.IOException
        {
          Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
          StringBuffer sb = new StringBuffer();

          sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
          .append(label)
          .append("</label>");

          sb.append("<span class=\"col-md-8\">")
            .append(doAuthority(pageContext, fieldName, 0,  defaults.length,
                                  fieldName, null, Choices.CF_UNSET, false, repeatable,
                                  defaults, null, collectionID))

            .append("</span></div><br/>");
          out.write(sb.toString());
        }



        /** Display Checkboxes or Radio buttons, depending on if repeatable! **/
        void doList(javax.servlet.jsp.JspWriter out, Item item,
                String fieldName, String schema, String element, String qualifier, boolean repeatable,
                boolean required,boolean readonly, List valueList, String label)
                throws java.io.IOException
              {
                    Metadatum[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
                    int valueCount = valueList.size();

                StringBuffer sb = new StringBuffer();
                String display, value;
                int j;

                int numColumns = 1;
                //if more than 3 display+value pairs, display in 2 columns to save space
                if(valueCount > 6)
                    numColumns = 2;

                //print out the field label
    			sb.append("<div class=\"row\"><label class=\"col-md-2"+ (required?" label-required":"") +"\">")
            	  .append(label)
            	  .append("</label>");

                sb.append("<div class=\"col-md-10\">");

                if(numColumns > 1)
                    sb.append("<div class=\"row col-md-"+(12 / numColumns)+"\">");
                else
                    sb.append("<div class=\"row col-md-12\">");

                //flag that lets us know when we are in Column2
                boolean inColumn2 = false;

                //loop through all values
                for (int i = 0; i < valueList.size(); i += 2)
                {
                       //get display value and actual value
    	               display = (String)valueList.get(i);
                       value = (String)valueList.get(i+1);

                       boolean checked = false;
                       //check if this value has been selected previously
                       for (j = 0; j < defaults.length; j++)
                       {
                            if (value.equals(defaults[j].value))
                            {
                            	checked = true;
                            	break;
                            }
    	               }

                       // print input field
                       sb.append("<div class=\"input-group\"><span class=\"input-group-addon\">");
                       sb.append("<input type=\"");

                       //if repeatable, print a Checkbox, otherwise print Radio buttons
                       if(repeatable)
                          sb.append("checkbox");
                       else
                          sb.append("radio");
                       if (readonly)
                       {
                           sb.append("\" disabled=\"disabled");
                       }
                       sb.append("\" name=\"")
                         .append(fieldName)
                         .append("\"")
                         .append(j < defaults.length ? " checked=\"checked\" " : "")
                         .append(" value=\"")
                                     .append(value.replaceAll("\"", "&quot;"))
                                     .append("\">");
                       sb.append("</span>");

                       //print display name immediately after input
                       sb.append("<span class=\"form-control\">")
                         .append(display)
                         .append("</span></div>");

                               // if we are writing values in two columns,
                               // then start column 2 after half of the values
                       if((numColumns == 2) && (i+2 >= (valueList.size()/2)) && !inColumn2)
                       {
                            //end first column, start second column
                            sb.append("</div>");
                            sb.append("<div class=\"row col-md-"+(12 / numColumns)+"\">");
                            inColumn2 = true;
                       }

                }//end for each value

                sb.append("</div></div></div><br/>");

                out.write(sb.toString());
              }//end doList
    %>
<%!
     StringBuffer doAuthority(MetadataAuthorityManager mam, ChoiceAuthorityManager cam,
            PageContext pageContext,
            String contextPath, String fieldName, String idx,
            Metadatum dcv, int collectionID)
    {
        StringBuffer sb = new StringBuffer();
        if (cam.isChoicesConfigured(fieldName))
        {
            boolean authority = mam.isAuthorityControlled(fieldName);
            boolean required = authority && mam.isAuthorityRequired(fieldName);
           
            String fieldNameIdx = "value_" + fieldName + "_" + idx;
            String authorityName = "choice_" + fieldName + "_authority_" + idx;
            String confidenceName = "choice_" + fieldName + "_confidence_" + idx;

            // put up a SELECT element containing all choices
            if ("select".equals(cam.getPresentation(fieldName)))
            {
                sb.append("<select class=\"form-control\" id=\"").append(fieldNameIdx)
                   .append("\" name=\"").append(fieldNameIdx)
                   .append("\" size=\"1\">");
                Choices cs = cam.getMatches(fieldName, dcv.value, collectionID, 0, 0, null);
                if (cs.defaultSelected < 0)
                    sb.append("<option value=\"").append(dcv.value).append("\" selected>")
                      .append(dcv.value).append("</option>\n");

                for (int i = 0; i < cs.values.length; ++i)
                {
                    sb.append("<option value=\"").append(cs.values[i].value).append("\"")
                      .append(i == cs.defaultSelected ? " selected>":">")
                      .append(cs.values[i].label).append("</option>\n");
                }
                sb.append("</select>\n");
            }

              // use lookup for any other presentation style (i.e "select")
            else
            {
                String confidenceIndicator = "indicator_"+confidenceName;
                sb.append("<textarea class=\"form-control\" id=\"").append(fieldNameIdx).append("\" name=\"").append(fieldNameIdx)
                   .append("\" rows=\"3\" cols=\"50\">")
                   .append(dcv.value).append("</textarea>\n<br/>\n");

                if (authority)
                {
                    String confidenceSymbol = Choices.getConfidenceText(dcv.confidence).toLowerCase();
                    sb.append("<span class=\"col-md-1\">")
                      .append("<img id=\""+confidenceIndicator+"\"  title=\"")
                      .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.authority.confidence.description."+confidenceSymbol))
                      .append("\" class=\"ds-authority-confidence cf-"+ confidenceSymbol)
                      .append("\" src=\"").append(contextPath).append("/image/confidence/invisible.gif\" />")
                      .append("</span>");
                  sb.append("<span class=\"col-md-5\">")
                      .append("<input class=\"form-control\" type=\"text\" readonly value=\"")
                      .append(dcv.authority != null ? dcv.authority : "")
                      .append("\" id=\"").append(authorityName)
                      .append("\" onChange=\"javascript: return DSpaceAuthorityOnChange(this, '")
                      .append(confidenceName).append("','").append(confidenceIndicator)
                      .append("');\" name=\"").append(authorityName).append("\" class=\"ds-authority-value ds-authority-visible \"/>")
                      .append("<input type=\"image\" class=\"ds-authority-lock is-locked \" ")
                      .append(" src=\"").append(contextPath).append("/image/confidence/invisible.gif\" ")
                      .append(" onClick=\"javascript: return DSpaceToggleAuthorityLock(this, '").append(authorityName).append("');\" ")
                      .append(" title=\"")
                      .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.tools.edit-item-form.unlock"))
                      .append("\" >")
                      .append("<input type=\"hidden\" value=\"").append(confidenceSymbol).append("\" id=\"").append(confidenceName)
                      .append("\" name=\"").append(confidenceName)
                      .append("\" class=\"ds-authority-confidence-input\"/>")
                      .append("</span>");
                }
                 
               sb.append("<span class=\"col-md-1\">")
                 .append("<button class=\"form-control\" name=\"").append(fieldNameIdx).append("_lookup\" ")
                 .append("onclick=\"javascript: return DSpaceChoiceLookup('")
                 .append(contextPath).append("/tools/lookup.jsp','")
                 .append(fieldName).append("','edit_metadata','")
                 .append(fieldNameIdx).append("','").append(authorityName).append("','")
                 .append(confidenceIndicator).append("',")
                 .append(String.valueOf(collectionID)).append(",")
                 .append("false").append(",false);\"")
                 .append(" title=\"")
                 .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.tools.lookup.lookup"))
                 .append("\"><span class=\"glyphicon glyphicon-search\"></span></button></span>");
            }
        }
        return sb;
    }
%>

<c:set var="dspace.layout.head.last" scope="request">
  <script type="text/javascript" src="<%= request.getContextPath() %>/static/js/scriptaculous/prototype.js"></script>
  <script type="text/javascript" src="<%= request.getContextPath() %>/static/js/scriptaculous/builder.js"></script>
  <script type="text/javascript" src="<%= request.getContextPath() %>/static/js/scriptaculous/effects.js"></script>
  <script type="text/javascript" src="<%= request.getContextPath() %>/static/js/scriptaculous/controls.js"></script>    
    <script type="text/javascript" src="<%= request.getContextPath() %>/dspace-admin/js/bitstream-ordering.js"></script>
</c:set>

<dspace:layout style="submission" titlekey="jsp.tools.edit-item-form.title"
               navbar="admin"
               locbar="link"
               parenttitlekey="jsp.administer"
               parentlink="/dspace-admin"
               nocache="true">


    <%-- <h1>Edit Item</h1> --%>
        <h1><fmt:message key="jsp.tools.edit-item-form.title"/>
        <dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.collection-admin\") + \"#editmetadata\"%>"><fmt:message key="jsp.morehelp"/></dspace:popup>
        </h1>
    
    <%-- <p><strong>PLEASE NOTE: These changes are not validated in any way.
    You are responsible for entering the data in the correct format.
    If you are not sure what the format is, please do NOT make changes.</strong></p> --%>
    <p class="alert alert-danger"><strong><fmt:message key="jsp.tools.edit-item-form.note"/></strong></p>

  <div class="row">
  <div class="col-md-9">
    <div class="panel panel-primary">
      <div class="panel-heading"><fmt:message key="jsp.tools.edit-item-form.details" /></div>

      <div class="panel-body">
        <table class="table">
          <tr>
            <td><fmt:message key="jsp.tools.edit-item-form.itemID" />
            </td>
            <td><%= item.getID() %></td>
          </tr>

          <tr>
            <td><fmt:message key="jsp.tools.edit-item-form.handle" />
            </td>
            <td><%= (handle == null ? "None" : handle) %></td>
          </tr>
          <tr>
            <td><fmt:message key="jsp.tools.edit-item-form.modified" />
            </td>
            <td><dspace:date
                date="<%= new DCDate(item.getLastModified()) %>" />
            </td>
          </tr>


          <%-- <td class="submitFormLabel">In Collections:</td> --%>
          <tr>
            <td><fmt:message key="jsp.tools.edit-item-form.collections" />
            </td>
            <td>
              <%  for (int i = 0; i < collections.length; i++) { %> <%= collections[i].getMetadata("name") %>
              <br /> <%  } %>
            </td>
          </tr>
          <tr>
            <%-- <td class="submitFormLabel">Item page:</td> --%>
            <td><fmt:message key="jsp.tools.edit-item-form.itempage" />
            </td>
            <td>
              <%  if (handle == null) { %> <em><fmt:message
                  key="jsp.tools.edit-item-form.na" />
            </em> <%  } else {
            String url = ConfigurationManager.getProperty("dspace.url") + "/handle/" + handle; %>
              <a target="_blank" href="<%= url %>"><%= url %></a> <%  } %>
            </td>
          </tr>


        </table>
      </div>
    </div>
  </div>

  <div class="col-md-3">
    <div class="panel panel-admin-tools">
      <div class="panel-heading"><fmt:message key="jsp.actiontools"/></div>
          <div class="panel-body">
          <%
    if (!item.isWithdrawn() && bWithdraw)
    {
%>
                    <form method="post" action="<%= request.getContextPath() %>/tools/edit-item">
                        <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                        <input type="hidden" name="action" value="<%= EditItemServlet.START_WITHDRAW %>" />
                        <%-- <input type="submit" name="submit" value="Withdraw..."> --%>
            <input class="btn btn-warning col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.tools.edit-item-form.withdraw-w-confirm.button"/>"/>
                    </form>
<%
    }
    else if (item.isWithdrawn() && bReinstate)
    {
%>
                    <form method="post" action="<%= request.getContextPath() %>/tools/edit-item">
                        <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                        <input type="hidden" name="action" value="<%= EditItemServlet.REINSTATE %>" />
                        <%-- <input type="submit" name="submit" value="Reinstate"> --%>
            <input class="btn btn-warning col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.tools.edit-item-form.reinstate.button"/>"/>
                    </form>
<%
    }
%>
<%
  if (bDelete)
  {
%>
                    <form method="post" action="<%= request.getContextPath() %>/tools/edit-item">
                        <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                        <input type="hidden" name="action" value="<%= EditItemServlet.START_DELETE %>" />
                        <%-- <input type="submit" name="submit" value="Delete (Expunge)..."> --%>
                        <input class="btn btn-danger col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.tools.edit-item-form.delete-w-confirm.button"/>"/>
                    </form>
<%
  }
%>
<%
  if (isItemAdmin)
  {
%>                     
          <form method="post" action="<%= request.getContextPath() %>/tools/edit-item">
                        <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                        <input type="hidden" name="action" value="<%= EditItemServlet.START_MOVE_ITEM %>" />
            <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.tools.edit-item-form.move-item.button"/>"/>
                    </form>
<%
  }
%>
<%
    if (item.isDiscoverable() && bPrivating)
    {
%>
                    <form method="post" action="<%= request.getContextPath() %>/tools/edit-item">
                        <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                        <input type="hidden" name="action" value="<%= EditItemServlet.START_PRIVATING %>" />
                        <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.tools.edit-item-form.privating-w-confirm.button"/>"/>
                    </form>
<%
    }
    else if (!item.isDiscoverable() && bPublicize)
    {
%>
                    <form method="post" action="<%= request.getContextPath() %>/tools/edit-item">
                        <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                        <input type="hidden" name="action" value="<%= EditItemServlet.PUBLICIZE %>" />
                        <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.tools.edit-item-form.publicize.button"/>"/>
                    </form>
<%
    }
%>

<%
  if (bPolicy)
  {
%>
  <%-- ===========================================================
     Edit item's policies
     =========================================================== --%>
              <form method="post"
                action="<%= request.getContextPath() %>/tools/authorize">
                <input type="hidden" name="handle"
                  value="<%= ConfigurationManager.getProperty("handle.prefix") %>" />
                <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                <%-- <input type="submit" name="submit_item_select" value="Edit..."> --%>
                <input class="btn btn-default col-md-12" type="submit"
                  name="submit_item_select"
                  value="<fmt:message key="jsp.tools.edit-item-form.item" />" />
              </form>
<%
  }
%>
<%
  if (isItemAdmin)
  {
%>
<%-- ===========================================================
     Curate Item
     =========================================================== --%>
              <form method="post"
                action="<%= request.getContextPath() %>/tools/curate">
                <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                <input class="btn btn-default col-md-12" type="submit"
                  name="submit_item_select"
                  value="<fmt:message key="jsp.tools.edit-item-form.form.button.curate"/>" />
              </form>
          <%
            }
          %>
          </div>
        </div>
  </div>
    </div>


  
<%

    if (item.isWithdrawn())
    {
%>
    <%-- <p align="center"><strong>This item was withdrawn from DSpace</strong></p> --%>
        <p class="alert alert-warning"><fmt:message key="jsp.tools.edit-item-form.msg"/></p>
<%
    }
%>
    <form id="edit_metadata" name="edit_metadata" method="post" action="<%= request.getContextPath() %>/tools/edit-item">
    <div class="table-responsive">
        <table class="table" summary="Edit item withdrawn table">
            <tr>
<%
    MetadataAuthorityManager mam = MetadataAuthorityManager.getManager();
    ChoiceAuthorityManager cam = ChoiceAuthorityManager.getManager();
    String row = "even";
            final int halfWidth = 23;
            final int fullWidth = 50;
            final int twothirdsWidth = 34;


            Integer pageNumStr = 1;

            int pageNum = pageNumStr.intValue();

            // Fetch the document type (dc.type)
            String documentType = "";
            if( (item.getMetadataByMetadataString("dc.type") != null) && (item.getMetadataByMetadataString("dc.type").length >0) )
            {
                documentType = item.getMetadataByMetadataString("dc.type")[0].value;
            }


        // owning Collection ID for choice authority calls
        int collectionID = -1;
        if (collections.length > 0)
            collectionID = collections[0].getID();

        DCInputSet inputSet =
                (DCInputSet) request.getAttribute("submission.inputs");

        DCInput[] inputs = inputSet.getPageRows(0, true, true );

        for (int z = 0; z < inputs.length; z++)
        {
          boolean readonly = false;


          String dcElement = inputs[z].getElement();
          String dcQualifier = inputs[z].getQualifier();
          String dcSchema = inputs[z].getSchema();

          String fieldName;
          int fieldCountIncr;
          boolean repeatable;
          String vocabulary;
   	   boolean required;

          vocabulary = inputs[z].getVocabulary();
          required = inputs[z].isRequired();

          if (dcQualifier != null && !dcQualifier.equals("*"))
             fieldName = dcSchema + "_" + dcElement + '_' + dcQualifier;
          else
             fieldName = dcSchema + "_" + dcElement;

          repeatable = inputs[z].getRepeatable();
          fieldCountIncr = 0;
          if (repeatable)
          {
            fieldCountIncr = 1;

          }

          String inputType = inputs[z].getInputType();
          String label = inputs[z].getLabel();
          boolean closedVocabulary = inputs[z].isClosedVocabulary();

          if (inputType.equals("name"))
          {
              doPersonalName(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                             repeatable, required, readonly, fieldCountIncr, label, pageContext, collectionID);
          }
          else if (isSelectable(fieldName))
          {
              doChoiceSelect(out, pageContext, item, fieldName, dcSchema, dcElement, dcQualifier,
                                      repeatable, required, readonly, inputs[z].getPairs(), label, collectionID);
          }
          else if (inputType.equals("date"))
          {
              doDate(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                             repeatable, required, readonly, fieldCountIncr, label, pageContext, request);
          }
           else if (inputType.equals("semester"))
                 {
                      doSemester(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                           repeatable, required, readonly, fieldCountIncr, label, pageContext, request);
                 }
          else if (inputType.equals("series"))
          {
              doSeriesNumber(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                 repeatable, required, readonly, fieldCountIncr, label, pageContext);
          }
          else if (inputType.equals("qualdrop_value"))
          {
              doQualdropValue(out, item, fieldName, dcSchema, dcElement, inputSet, repeatable, required,
                                      readonly, fieldCountIncr, inputs[z].getPairs(), label, pageContext);
          }
          else if (inputType.equals("textarea"))
          {
                      doTextArea(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                     repeatable, required, readonly, fieldCountIncr, label, pageContext, vocabulary,
                                     closedVocabulary, collectionID);
          }
          else if (inputType.equals("dropdown"))
          {
                           doDropDown(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                      repeatable, required, readonly, inputs[z].getPairs(), label);
          }
          else if (inputType.equals("twobox"))
          {
                           doTwoBox(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                    repeatable, required, readonly, fieldCountIncr, label, pageContext,
                                    vocabulary, closedVocabulary);
          }
          else if (inputType.equals("list"))
          {
             doList(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                           repeatable, required, readonly, inputs[z].getPairs(), label);
          }
          else
          {
                           doOneBox(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                    repeatable, required, readonly, fieldCountIncr, label, pageContext, vocabulary,
                                    closedVocabulary, collectionID);
          }

        } // end of 'for rows'%>

        </tr>
        
        <br/>

        <%-- <h2>Bitstreams</h2> --%>
                <h2><fmt:message key="jsp.tools.edit-item-form.heading"/></h2>

        <%-- <p>Note that if the "user format description" field isn't empty, the format will
        always be set to "Unknown", so clear the user format description before changing the
        format field.</p> --%>
                <p class="alert alert-warning"><fmt:message key="jsp.tools.edit-item-form.note3"/></p>
  <div class="table-responsive">
        <table id="bitstream-edit-form-table" class="table" summary="Bitstream data table">
            <tr>
          <%-- <th class="oddRowEvenCol"><strong>Primary<br>Bitstream</strong></th>
                <th class="oddRowOddCol"><strong>Name</strong></th>
                <th class="oddRowEvenCol"><strong>Source</strong></th>
                <th class="oddRowOddCol"><strong>Description</strong></th>
                <th class="oddRowEvenCol"><strong>Format</strong></th>
                <th class="oddRowOddCol"><strong>User&nbsp;Format&nbsp;Description</strong></th> --%>
                <th id="t10" class="oddRowEvenCol">&nbsp;</th>
                <th id="t11" class="oddRowOddCol"><strong><fmt:message key="jsp.tools.edit-item-form.elem5"/></strong></th>        
                <th id="t12" class="oddRowEvenCol"><strong><fmt:message key="jsp.tools.edit-item-form.elem7"/></strong></th>
                <th id="t13" class="oddRowOddCol"><strong><fmt:message key="jsp.tools.edit-item-form.elem8"/></strong></th>
                <th id="t14" class="oddRowEvenCol"><strong><fmt:message key="jsp.tools.edit-item-form.elem9"/></strong></th>
                <th id="t15" class="oddRowOddCol"><strong><fmt:message key="jsp.tools.edit-item-form.elem10"/></strong></th>
                <th id="t16" class="oddRowEvenCol"><strong><fmt:message key="jsp.tools.edit-item-form.elem11"/></strong></th>
                <th id="t17" class="oddRowOddCol"><strong><fmt:message key="jsp.tools.edit-item-form.elem12"/></strong></th>
                <th id="t18" class="oddRowEvenCol">&nbsp;</th>
            </tr>
<%
    Bundle[] bundles = item.getBundles();
    row = "even";

    for (int i = 0; i < bundles.length; i++)
    {
        Bitstream[] bitstreams = bundles[i].getBitstreams();
        Arrays.sort(bitstreams, new BitstreamComparator());
        for (int j = 0; j < bitstreams.length; j++)
        {
            ArrayList<Integer> bitstreamIdOrder = new ArrayList<Integer>();
            for (Bitstream bitstream : bitstreams) {
                bitstreamIdOrder.add(bitstream.getID());
            }

            // Parameter names will include the bundle and bitstream ID
            // e.g. "bitstream_14_18_desc" is the description of bitstream 18 in bundle 14
            String key = bundles[i].getID() + "_" + bitstreams[j].getID();
            BitstreamFormat bf = bitstreams[j].getFormat();
%>
            <tr id="<%="row_" + bundles[i].getName() + "_" + bitstreams[j].getID()%>">
              <td headers="t10" class="<%= row %>RowEvenCol" align="center">
                  <%-- <a target="_blank" href="<%= request.getContextPath() %>/retrieve/<%= bitstreams[j].getID() %>">View</a>&nbsp;<input type="submit" name="submit_delete_bitstream_<%= key %>" value="Remove"> --%>
          <a class="btn btn-info" target="_blank" href="<%= request.getContextPath() %>/retrieve/<%= bitstreams[j].getID() %>"><fmt:message key="jsp.tools.general.view"/></a>&nbsp;
        </td>
                <% if (bundles[i].getName().equals("ORIGINAL"))
                   { %>
                     <td headers="t11" class="<%= row %>RowEvenCol" align="center">
                       <span class="form-control">
                       <input type="radio" name="<%= bundles[i].getID() %>_primary_bitstream_id" value="<%= bitstreams[j].getID() %>"
                           <% if (bundles[i].getPrimaryBitstreamID() == bitstreams[j].getID()) { %>
                                  checked="<%="checked" %>"
                           <% } %> /></span>
                   </td>
                <% } else { %>
                     <td headers="t11"> </td>
                <% } %>
                <td headers="t12" class="<%= row %>RowOddCol">
                    <input class="form-control" type="text" name="bitstream_name_<%= key %>" value="<%= (bitstreams[j].getName() == null ? "" : Utils.addEntities(bitstreams[j].getName())) %>"/>
                </td>
                <td headers="t13" class="<%= row %>RowEvenCol">
                    <input class="form-control" type="text" name="bitstream_source_<%= key %>" value="<%= (bitstreams[j].getSource() == null ? "" : bitstreams[j].getSource()) %>"/>
                </td>
                <td headers="t14" class="<%= row %>RowOddCol">
                    <input class="form-control" type="text" name="bitstream_description_<%= key %>" value="<%= (bitstreams[j].getDescription() == null ? "" : Utils.addEntities(bitstreams[j].getDescription())) %>"/>
                </td>
                <td headers="t15" class="<%= row %>RowEvenCol">
                    <input class="form-control" type="text" name="bitstream_format_id_<%= key %>" value="<%= bf.getID() %>" size="4"/> (<%= Utils.addEntities(bf.getShortDescription()) %>)
                </td>
                <td headers="t16" class="<%= row %>RowOddCol">
                    <input class="form-control" type="text" name="bitstream_user_format_description_<%= key %>" value="<%= (bitstreams[j].getUserFormatDescription() == null ? "" : Utils.addEntities(bitstreams[j].getUserFormatDescription())) %>"/>
                </td>
<%
                   if (bundles[i].getName().equals("ORIGINAL") && breOrderBitstreams)
                   {
                       //This strings are only used in case the user has javascript disabled
                       String upButtonValue = null;
                       String downButtonValue = null;
                       if(0 != j){
                           ArrayList<Integer> temp = (ArrayList<Integer>) bitstreamIdOrder.clone();
                           //We don't have the first button, so create a value where the current bitstreamId moves one up
                           Integer tempInt = temp.get(j);
                           temp.set(j, temp.get(j - 1));
                           temp.set(j - 1, tempInt);
                           upButtonValue = StringUtils.join(temp.toArray(new Integer[temp.size()]), ",");
                       }
                       if(j < (bitstreams.length -1)){
                           //We don't have the first button, so create a value where the current bitstreamId moves one up
                           ArrayList<Integer> temp = (ArrayList<Integer>) bitstreamIdOrder.clone();
                           Integer tempInt = temp.get(j);
                           temp.set(j, temp.get(j + 1));
                           temp.set(j + 1, tempInt);
                           downButtonValue = StringUtils.join(temp.toArray(new Integer[temp.size()]), ",");
                       }



%>
                <td headers="t17" class="<%= row %>RowEvenCol">
                    <input type="hidden" value="<%=j+1%>" name="order_<%=bitstreams[j].getID()%>">
                    <input type="hidden" value="<%=upButtonValue%>" name="<%=bundles[i].getID()%>_<%=bitstreams[j].getID()%>_up_value">
                    <input type="hidden" value="<%=downButtonValue%>" name="<%=bundles[i].getID()%>_<%=bitstreams[j].getID()%>_down_value">
                    <div>
                        <button class="btn btn-default" name="submit_order_<%=key%>_up" value="<fmt:message key="jsp.tools.edit-item-form.move-up"/> " <%=j==0 ? "disabled=\"disabled\"" : ""%>>
                          <span class="glyphicon glyphicon-arrow-up"></span>
                        </button>
                    </div>
                    <div>
                        <button class="btn btn-default" name="submit_order_<%=key%>_down" value="<fmt:message key="jsp.tools.edit-item-form.move-down"/> " <%=j==(bitstreams.length-1) ? "disabled=\"disabled\"" : ""%>>
                          <span class="glyphicon glyphicon-arrow-down"></span>
                        </button>
                    </div>
                </td>

<%
                   }else{
%>
                <td>
                    <%=j+1%>
                </td>
<%
                   }
%>
                <td headers="t18" class="<%= row %>RowEvenCol">

                                        <% if (bRemoveBits) { %>
                                        <button class="btn btn-danger" name="submit_delete_bitstream_<%= key %>" value="<fmt:message key="jsp.tools.general.remove"/>">
                                          <span class="glyphicon glyphicon-trash"></span>
                                        </button>
                                        <% } %>
                </td>
            </tr>
<%
            row = (row.equals("odd") ? "even" : "odd");
        }
    }
%>
        </table>
  </div>
        

        <%-- <p align="center"><input type="submit" name="submit_addbitstream" value="Add Bitstream"></p> --%>
  <div class="btn-group col-md-12">
                <%
          if (bCreateBits) {
                %>                
          <input class="btn btn-success col-md-2" type="submit" name="submit_addbitstream" value="<fmt:message key="jsp.tools.edit-item-form.addbit.button"/>"/>
                <%  }
                    if(breOrderBitstreams){
                %>
                    <input class="hidden" type="submit" value="<fmt:message key="jsp.tools.edit-item-form.order-update"/>" name="submit_update_order" style="visibility: hidden;">
                <%
                    }

                        if (ConfigurationManager.getBooleanProperty("webui.submit.enable-cc") && bccLicense)
                        {
                                String s;
                                Bundle[] ccBundle = item.getBundles("CC-LICENSE");
                                s = ccBundle.length > 0 ? LocaleSupport.getLocalizedMessage(pageContext, "jsp.tools.edit-item-form.replacecc.button") : LocaleSupport.getLocalizedMessage(pageContext, "jsp.tools.edit-item-form.addcc.button");
                %>
                    <input class="btn btn-success col-md-2" type="submit" name="submit_addcc" value="<%= s %>" />
                    <input type="hidden" name="handle" value="<%= ConfigurationManager.getProperty("handle.prefix") %>"/>
                    <input type="hidden" name="item_id" value="<%= item.getID() %>"/>
                    
            <%
                  }
        %>
  


        <input type="hidden" name="item_id" value="<%= item.getID() %>"/>
        <input type="hidden" name="action" value="<%= EditItemServlet.UPDATE_ITEM %>"/>
          
                        <%-- <input type="submit" name="submit" value="Update" /> --%>
                        <input class="btn btn-primary pull-right col-md-3" type="submit" name="submit" value="<fmt:message key="jsp.tools.general.update"/>" />
                        <%-- <input type="submit" name="submit_cancel" value="Cancel" /> --%>
            <input class="btn btn-default pull-right col-md-3" type="submit" name="submit_cancel" value="<fmt:message key="jsp.tools.general.cancel"/>" />
          </div>
    </form>
</dspace:layout>
