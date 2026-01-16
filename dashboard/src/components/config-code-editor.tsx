'use client';

import Editor from 'react-simple-code-editor';
import { highlight, languages } from 'prismjs';
import 'prismjs/components/prism-bash';
import 'prismjs/components/prism-markdown';
import 'prismjs/components/prism-yaml';
import 'prismjs/components/prism-json';
import { cn } from '@/lib/utils';

type SupportedLanguage = 'markdown' | 'bash' | 'text' | 'json';

interface ConfigCodeEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  disabled?: boolean;
  className?: string;
  editorClassName?: string;
  minHeight?: number | string;
  language?: SupportedLanguage;
  padding?: number;
  /** Enable highlighting of <encrypted>...</encrypted> tags */
  highlightEncrypted?: boolean;
  /** Whether the editor should scroll internally. Set to false when parent handles scrolling. */
  scrollable?: boolean;
}

const languageMap: Record<SupportedLanguage, Prism.Grammar | undefined> = {
  markdown: languages.markdown,
  bash: languages.bash,
  text: undefined,
  json: languages.json,
};

const escapeHtml = (code: string) =>
  code
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');

/**
 * Encrypted tag highlighting using marker-based pre/post processing.
 * This approach handles PrismJS wrapping content in span tags.
 */
const ENCRYPTED_TAG_RAW = /<encrypted(?:\s+v="\d+")?>(.*?)<\/encrypted>/g;

// Unique markers that won't appear in normal content
const MARKER_OPEN = '\u200B\u200BENCOPEN\u200B\u200B';
const MARKER_CLOSE = '\u200B\u200BENCCLOSE\u200B\u200B';
const MARKER_VALUE_START = '\u200B\u200BENCVAL\u200B\u200B';
const MARKER_VALUE_END = '\u200B\u200BENCVALEND\u200B\u200B';

/** Pre-process code to replace encrypted tags with markers before PrismJS */
const preprocessEncryptedTags = (code: string): string => {
  return code.replace(
    ENCRYPTED_TAG_RAW,
    `${MARKER_OPEN}${MARKER_VALUE_START}$1${MARKER_VALUE_END}${MARKER_CLOSE}`
  );
};

/** Post-process highlighted HTML to replace markers with styled content */
const postprocessEncryptedTags = (html: string): string => {
  // The markers get HTML-escaped by PrismJS, so we need to match the escaped versions
  // Zero-width spaces are not escaped, so markers remain intact
  return html
    .replace(new RegExp(MARKER_OPEN, 'g'), '<span class="encrypted-tag" style="color: #fbbf24;">&lt;encrypted&gt;</span>')
    .replace(new RegExp(MARKER_VALUE_START, 'g'), '<span class="encrypted-value" style="color: #f59e0b; background: rgba(251, 191, 36, 0.1); padding: 0 2px; border-radius: 2px;">')
    .replace(new RegExp(MARKER_VALUE_END, 'g'), '</span>')
    .replace(new RegExp(MARKER_CLOSE, 'g'), '<span class="encrypted-tag" style="color: #fbbf24;">&lt;/encrypted&gt;</span>');
};

export function ConfigCodeEditor({
  value,
  onChange,
  placeholder,
  disabled = false,
  className,
  editorClassName,
  minHeight = '100%',
  language = 'markdown',
  padding = 12,
  highlightEncrypted = false,
  scrollable = true,
}: ConfigCodeEditorProps) {
  const grammar = languageMap[language];
  const highlightCode = (code: string) => {
    // Pre-process to replace encrypted tags with markers
    let processedCode = highlightEncrypted ? preprocessEncryptedTags(code) : code;

    let html: string;
    if (!grammar) {
      html = escapeHtml(processedCode);
    } else {
      html = highlight(processedCode, grammar, language);
    }

    // Post-process to replace markers with styled HTML
    if (highlightEncrypted) {
      html = postprocessEncryptedTags(html);
    }
    return html;
  };

  return (
    <div
      className={cn(
        'rounded-lg bg-[#0d0d0e] border border-white/[0.06] focus-within:border-indigo-500/50 transition-colors',
        scrollable ? 'overflow-auto' : 'overflow-hidden',
        disabled && 'opacity-60',
        className
      )}
      aria-disabled={disabled}
    >
      <Editor
        value={value}
        onValueChange={onChange}
        highlight={highlightCode}
        padding={padding}
        placeholder={placeholder}
        readOnly={disabled}
        spellCheck={false}
        className={cn('config-code-editor', editorClassName)}
        textareaClassName="focus:outline-none"
        preClassName="whitespace-pre-wrap break-words"
        style={{
          fontFamily:
            'ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace',
          fontSize: 14,
          lineHeight: 1.6,
          color: 'rgba(255, 255, 255, 0.9)',
          minHeight,
          wordBreak: 'break-word',
          overflowWrap: 'break-word',
        }}
      />
    </div>
  );
}
