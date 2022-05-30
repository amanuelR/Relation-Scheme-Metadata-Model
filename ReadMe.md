<h2> Relation Scheme Metadata Modeling </h2>

The relation scheme diagram serves as a bridge from the conceptual model that we capture in the UML class modeling language, and the relational
implementation. Sadly, there is no tool that we can use that will take the relation scheme diagram and convert it directly into DDL statements that we can then
submit to the database to build the tables. If there was such a tool, it would save us a great deal of time, as well as provide a quality check on the eventual physical
database.
In this project, I am going to model the information content of the relation scheme diagram, combined with the database model into one model, and then write code to
    <br>a) enforce important constraints on the data that we put into our meta data database, and 
    <br>b) produce useful output (like the DDL statements to create the corresponding tables).
