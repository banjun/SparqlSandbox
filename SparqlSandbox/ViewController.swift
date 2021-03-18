import Cocoa
import Antlr4
import NorthLayout
import Ikemen

class ViewController: NSViewController, NSTextViewDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private var query: String = "" {
        didSet {
            let input = ANTLRInputStream(query)
            let lexer = SparqlLexer(input)
            let tokens = CommonTokenStream(lexer)
            let parser = try! SparqlParser(tokens)

            let query = try! parser.query()
            let result = query.toStringTree(parser)
            print(result)

            let listener = QueryListener()
            let walker = ParseTreeWalker()
            try! walker.walk(listener, query)
            parseResult = .init(parser: parser, query: query, terms: listener.terms)
        }
    }
    struct ParseResult {
        var parser: SparqlParser // required for traversing results such as getText()
        var query: SparqlParser.QueryContext
        var terms: [QueryListener.Term]
    }
    private var parseResult: ParseResult? {
        didSet {
            parseResultTextView.string = parseResult.map {$0.query.toStringTree($0.parser)} ?? ""
            terms = parseResult?.terms ?? []
        }
    }

    var terms: [QueryListener.Term] = [] {
        didSet {
            parsedTemsView.reloadData()
        }
    }

    private let queryTextView: NSTextView = .init() ※ {
        $0.isEditable = true
    }
    private let parseResultTextView: NSTextView = .init() ※ {
        $0.isEditable = false
    }
    private let parsedTemsView: NSTableView = .init() ※ {
        $0.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "term")) ※ {$0.title = "Term"})
    }

    override func loadView() {
        super.loadView()

        parsedTemsView.dataSource = self
        parsedTemsView.delegate = self

        let autolayout = view.northLayoutFormat([:], [
            "query": NSScrollView() ※ {
                $0.documentView = queryTextView
                queryTextView.autoresizingMask = .width
                $0.hasVerticalScroller = true
            },
            "result": NSScrollView() ※ {
                $0.documentView = parseResultTextView
                parseResultTextView.autoresizingMask = .width
                $0.hasVerticalScroller = true
                parseResultTextView.backgroundColor = .windowBackgroundColor
            },
            "terms": NSScrollView() ※ {
                $0.documentView = parsedTemsView
                parsedTemsView.autoresizingMask = .width
                $0.hasVerticalScroller = true
            },
        ])
        autolayout("H:|-[query][result(query)][terms(query)]-|")
        autolayout("V:|-[query]-|")
        autolayout("V:|-[result]-|")
        autolayout("V:|-[terms]-|")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        queryTextView.string = """
PREFIX dbpedia-owl: <http://dbpedia.org/ontology/>
PREFIX dbpprop: <http://dbpedia.org/property/>
PREFIX dbres: <http://dbpedia.org/resource/>

SELECT ?y WHERE {
 ?y dbpedia-owl:binomialAuthority dbres:Johan_Christian_Fabricius.
 }
"""

        queryTextView.delegate = self
    }

    func textDidChange(_ notification: Notification) {
        query = queryTextView.string
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        terms.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let term = terms[row]
        return term.attributedString
    }
}

final class QueryListener: SparqlBaseListener {
    var terms: [Term] = []
    enum Term {
        case graphTerm(SparqlParser.GraphTermContext)
        case `var`(SparqlParser.Var_Context)

        var kind: String {
            switch self {
            case .graphTerm: return "GraphTerm"
            case .var: return "Var"
            }
        }

        var text: String {
            switch self {
            case .graphTerm(let c): return c.getText()
            case .var(let c): return c.getText()
            }
        }

        var attributedString: NSAttributedString {
            [
                NSAttributedString(string: kind, attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .regular)]),
                NSAttributedString(string: "(", attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .regular)]),
                NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .semibold)]),
                NSAttributedString(string: ")", attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .regular)]),
            ].reduce(into: NSMutableAttributedString()) {$0.append($1)}
        }
    }

    override func enterGraphTerm(_ ctx: SparqlParser.GraphTermContext) {
        terms.append(.graphTerm(ctx))
    }

    override func enterVar_(_ ctx: SparqlParser.Var_Context) {
        terms.append(.var(ctx))
    }
}
