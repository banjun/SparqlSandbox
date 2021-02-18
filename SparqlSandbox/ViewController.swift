import Cocoa
import Antlr4

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let input = ANTLRInputStream("""
PREFIX dbpedia-owl: <http://dbpedia.org/ontology/>
PREFIX dbpprop: <http://dbpedia.org/property/>
PREFIX dbres: <http://dbpedia.org/resource/>

SELECT ?y WHERE {
 ?y dbpedia-owl:binomialAuthority dbres:Johan_Christian_Fabricius.
 }
""")
        let lexer = SparqlLexer(input)
        let tokens = CommonTokenStream(lexer)
        let parser = try! SparqlParser(tokens)

        let query = try! parser.query()
        print(query.toStringTree(parser))
    }
}

