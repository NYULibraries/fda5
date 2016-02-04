/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.webui.search;

import java.io.IOException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.dspace.core.Context;

public interface SearchRequestProcessor
{
    void doSimpleSearch(Context context, HttpServletRequest request,
                        HttpServletResponse response) throws SearchProcessorException,
            IOException, ServletException;

    void doAdvancedSearch(Context context, HttpServletRequest request,
                          HttpServletResponse response) throws SearchProcessorException,
            IOException, ServletException;

    void doOpenSearch(Context context, HttpServletRequest request,
                      HttpServletResponse response) throws SearchProcessorException,
            IOException, ServletException;

    void doItemMapSearch(Context context, HttpServletRequest request,
                         HttpServletResponse response) throws SearchProcessorException,
            IOException, ServletException;
    
    List<String> getSearchIndices();
    
    String getI18NKeyPrefix();

}
