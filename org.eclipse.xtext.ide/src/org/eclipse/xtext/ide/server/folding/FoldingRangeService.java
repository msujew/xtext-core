/*******************************************************************************
 * Copyright (c) 2021 TypeFox GmbH (http://www.typefox.io) and others.
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 * 
 * SPDX-License-Identifier: EPL-2.0
 *******************************************************************************/
package org.eclipse.xtext.ide.server.folding;

import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.lsp4j.FoldingRange;
import org.eclipse.lsp4j.Position;
import org.eclipse.xtext.ide.editor.folding.IFoldingRangeProvider;
import org.eclipse.xtext.ide.server.Document;
import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.util.CancelIndicator;

import com.google.inject.Inject;
import com.google.inject.Singleton;

/**
 * @author Mark Sujew - Initial contribution and API
 */
@Singleton
public class FoldingRangeService {

	@Inject
	private IFoldingRangeProvider foldingRangeProvider;

	public List<FoldingRange> createFoldingRanges(Document document, XtextResource resource,
			CancelIndicator cancelIndicator) {
		return foldingRangeProvider.getFoldingRanges(resource, cancelIndicator).stream()
				.map(range -> toFoldingRange(document, range))
				.filter(range -> range.getStartLine() < range.getEndLine()).collect(Collectors.toList());
	}

	protected FoldingRange toFoldingRange(Document document, org.eclipse.xtext.ide.editor.folding.FoldingRange range) {
		int offset = range.getOffset();
		int length = range.getLength();
		int endOffset = offset + length;
		Position start = document.getPosition(offset);
		Position end = document.getPosition(endOffset);
		FoldingRange result = new FoldingRange(start.getLine(), end.getLine());
		result.setStartCharacter(offset);
		result.setEndCharacter(endOffset);
		result.setKind(range.getKind());
		return result;
	}
}
