package org.dspace.app.webui.servlet;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.log4j.Logger;
import org.dspace.authorize.AuthorizeException;
import org.dspace.core.Context;

public class OAIRequestWrapper extends DSpaceServlet
{
    private static Logger log = Logger.getLogger(OAIRequestWrapper.class);

    protected void doDSGet(Context context, HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException, AuthorizeException
    {
        doDSPost(context, request, response);
    }

    protected void doDSPost(Context context, HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException
    {

        String destination = "/requestHandler";
        RequestDispatcher rd = getServletContext().getRequestDispatcher(destination);
        rd.forward(request, response);
    }
}