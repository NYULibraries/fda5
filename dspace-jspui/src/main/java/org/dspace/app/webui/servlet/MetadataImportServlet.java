/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.webui.servlet;

import java.io.*;
import java.sql.SQLException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.fileupload.FileUploadBase;
import org.apache.log4j.Logger;
import org.dspace.app.bulkedit.*;
import org.dspace.app.webui.util.JSPManager;
import org.dspace.app.webui.util.FileUploadRequest;
import org.dspace.authorize.AuthorizeException;
import org.dspace.authorize.AuthorizeManager;
import org.dspace.content.DSpaceObject;
import org.dspace.core.*;
import org.dspace.handle.HandleManager;

/**
 * Servlet to import metadata as CSV (comma separated values)
 *
 * @author Stuart Lewis
 */
public class MetadataImportServlet extends DSpaceServlet
{
    /** Upload limit */
    private int limit;

    /** log4j category */
    private static Logger log = Logger.getLogger(MetadataImportServlet.class);

    /**
     * Initalise the servlet
     */
    public void init()
    {
        // Set the lmimt to the number of items that may be changed in one go, default to 20
        limit = ConfigurationManager.getIntProperty("bulkedit", "gui-item-limit", 20);
        log.debug("Setting bulk edit limit to " + limit + " items");
    }

    /**
     * Respond to a post request for metadata bulk importing via csv
     *
     * @param context a DSpace Context object
     * @param request the HTTP request
     * @param response the HTTP response
     *
     * @throws ServletException
     * @throws IOException
     * @throws SQLException
     * @throws AuthorizeException
     */
    protected void doDSPost(Context context, HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException,
            SQLException, AuthorizeException
    {
        // First, see if we have a multipart request (uploading a metadata file)
        String contentType = request.getContentType();
        HttpSession session = request.getSession(true);
        String handle = request.getParameter("handle");

        if(handle==null) {
            handle = (String) request.getAttribute("handle");
        }
        DSpaceObject thing=null;

        if (handle != null) {
            log.info(LogManager.getHeader(context, "metadataimport", "importing_handle:" + handle));
            thing = HandleManager.resolveToObject(context, handle);
        }

        request.setAttribute("handle",handle);
        log.info("content"+contentType);

        if ((contentType != null) && (contentType.indexOf("multipart/form-data") != -1))
        {

            // Process the file uploaded
            try
            {



                // Get the changes
                log.info(LogManager.getHeader(context, "metadataimport", "loading file"));
                List<BulkEditChange> changes = processUpload(context, request);
                log.debug(LogManager.getHeader(context, "metadataimport", changes.size() + " items with changes identified"));                

                // Were there any changes detected?
                if (changes.size() != 0)
                {
                    request.setAttribute("changes", changes);
                    request.setAttribute("changed", false);

                    // Is the user allowed to make this many changes?
                    if (changes.size() <= limit)
                    {
                        request.setAttribute("allow", true);
                    }
                    else
                    {
                        request.setAttribute("allow", false);
                        session.removeAttribute("csv");
                        log.info(LogManager.getHeader(context, "metadataimport", "too many changes: " +
                                                      changes.size() + " (" + limit + " allowed)"));
                    }

                    JSPManager.showJSP(request, response, "/tools/metadataimport-showchanges.jsp");
                }
                else
                {
                    request.setAttribute("message", "No changes detected");
                    JSPManager.showJSP(request, response, "/tools/metadataimport.jsp");
                }
            }
            catch (MetadataImportInvalidHeadingException mihe) {
                request.setAttribute("message", mihe.getBadHeader());
                request.setAttribute("badheading", mihe.getType());
                log.info(LogManager.getHeader(context, "metadataimport", "Error encountered while looking for changes: " + mihe.getMessage()));                
                JSPManager.showJSP(request, response, "/tools/metadataimport-error.jsp");
            }
            catch (Exception e)
            {
                request.setAttribute("message", e.getMessage());
                log.info(LogManager.getHeader(context, "metadataimport", "Error encountered while looking for changes: " + e.getMessage()));                
                JSPManager.showJSP(request, response, "/tools/metadataimport-error.jsp");
            }

        }
        else if ("confirm".equals(request.getParameter("type")))
        {
            // Get the csv lines from the session
            DSpaceCSV csv = (DSpaceCSV)session.getAttribute("csv");

            // Make the changes
            try
            {
                MetadataImport mImport = new MetadataImport(context, csv);
                List<BulkEditChange> changes = mImport.runImport(true, false, false, false);

                // Commit the changes
                context.commit();
                log.debug(LogManager.getHeader(context, "metadataimport", changes.size() + " items changed"));

                // Blank out the session data
                session.removeAttribute("csv");

                request.setAttribute("changes", changes);
                request.setAttribute("changed", true);
                request.setAttribute("allow", true);
                JSPManager.showJSP(request, response, "/tools/metadataimport-showchanges.jsp");
            }
            catch (Exception e)
            {
                request.setAttribute("message", e.getMessage());
                log.debug(LogManager.getHeader(context, "metadataimport", "Error encountered while making changes: " + e.getMessage()));
                JSPManager.showJSP(request, response, "/tools/metadataimport-error.jsp");
            }
        }
        else if ("cancel".equals(request.getParameter("type")))
        {
            // Blank out the session data
            session.removeAttribute("csv");

            request.setAttribute("message", "Changes cancelled. No items have been modified.");
            log.debug(LogManager.getHeader(context, "metadataimport", "Changes cancelled"));
            JSPManager.showJSP(request, response, "/tools/metadataimport.jsp");
        }
        else
        {
            // Show the upload screen
            JSPManager.showJSP(request, response, "/tools/metadataimport.jsp");
        }
    }

    /**
     * GET request is only ever used to show the upload form
     * 
     * @param context
     *            a DSpace Context object
     * @param request
     *            the HTTP request
     * @param response
     *            the HTTP response
     *
     * @throws ServletException
     * @throws IOException
     * @throws SQLException
     * @throws AuthorizeException
     */
    protected void doDSGet(Context context, HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException,
            SQLException, AuthorizeException

    {

        String handle = request.getParameter("handle");
        request.setAttribute("handle",handle);

        // Show the upload screen
        JSPManager.showJSP(request, response, "/tools/metadataimport.jsp");
    }

    /**
     * Process the uploaded file.
     *
     * @param context The DSpace Context
     * @param request The request object
     * @return The response object
     * @throws Exception Thrown if an error occurs
     */
    private List<BulkEditChange> processUpload(Context context,
                                                    HttpServletRequest request) throws Exception
    {
        // Wrap multipart request to get the submission info
        FileUploadRequest wrapper = new FileUploadRequest(request);
        String handle = wrapper.getParameter("handle");

        if(handle==null) {
            handle=(String) wrapper.getAttribute("hanlde");
        }

        DSpaceObject thing=null;

        if (handle != null) {
            log.info(LogManager.getHeader(context, "metadataimport", "importing_handle:" + handle));
            thing = HandleManager.resolveToObject(context, handle);
        }

        //Authorize. added by Kate
        if(handle==null) {
            if (!AuthorizeManager.isAdmin(context)) throw new AuthorizeException("Not Authorized");
        } else {
            if (!AuthorizeManager.isAdmin(context,thing)) throw new AuthorizeException("Not Authorized");
        }
        File f = wrapper.getFile("file");

        // Run the import
        DSpaceCSV csv = new DSpaceCSV(f, context);
        MetadataImport mImport = new MetadataImport(context, csv);
        List<BulkEditChange> changes = mImport.runImport(false, false, false, false);

        // Store the csv lines in the session
        HttpSession session = request.getSession(true);
        session.setAttribute("csv", csv);

        // Remove temp file
        if (!f.delete())
        {
            log.error("Unable to delete upload file");
        }

        // Return the changes
        return changes;
    }
}