import Cocoa
import Antlr4
import NorthLayout
import Ikemen

class ViewController: NSViewController, NSTextViewDelegate {
    private var query: String = "" {
        didSet {
            let input = ANTLRInputStream(query)
            let lexer = SparqlLexer(input)
            let tokens = CommonTokenStream(lexer)
            let parser = try! SparqlParser(tokens)

            let query = try! parser.query()
            let result = query.toStringTree(parser)
            print(result)
            parseResultTextView.string = result
        }
    }
    private let queryTextView: NSTextView = .init() ※ {
        $0.isEditable = true
    }
    private let parseResultTextView: NSTextView = .init() ※ {
        $0.isEditable = false
    }

    override func loadView() {
        super.loadView()

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
            },
        ])
        autolayout("H:|-[query][result(query)]-|")
        autolayout("V:|-[query]-|")
        autolayout("V:|-[result]-|")
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
}

