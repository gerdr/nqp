my class NQPMu {
    method CREATE() {
        pir::repr_instance_of__PP(self)
    }

    method bless(NQPMu:U $self: *%attributes) {
        my $instance := self.CREATE();
        $instance.BUILDALL(|%attributes);
        $instance
    }

    method BUILDALL(NQPMu:D $self: *%attributes) {
        for $self.HOW.parents($self) -> $class {
            $self.BUILD_MAGIC($class, |%attributes);
        }
    }

    method BUILD_MAGIC(NQPMu:D $self: $type, *%attributes) {
        for $type.HOW.attributes($type, :local) {
            my $name := $_.name;
            my $shortname := pir::substr($name, 2);
            if pir::exists(%attributes, $shortname) {
                pir::setattribute__vPPsP($self, $type, $name, %attributes{$shortname});
            }
        }
    }

    method new(*%attributes) {
        self.bless(|%attributes);
    }

    proto method Str() is parrot_vtable('get_string') { * }
    multi method Str(NQPMu:U $self:) {
        self.HOW.name(self) ~ '()'
    }

    proto method ACCEPTS($topic) { * }
    multi method ACCEPTS(NQPMu:U $self: $topic) {
        pir::type_check__IPP($topic, self.WHAT)
    }
    
    method () is parrot_vtable('get_bool') {
        pir::repr_defined__IP(self)
    }

    method isa($type) {
        self.HOW.isa(self, $type)
    }

    method __dump($dumper, $label) {
        my $subindent;
        my $indent;
        Q:PIR {
            $P0 = find_lex '$dumper'
            ($P0, $P1) = $P0.'newIndent'()
            store_lex '$subindent', $P0
            store_lex '$indent', $P1
        };
        print('{');
        for self.HOW.parents(self) -> $type {
            my @attr := nqp::list();
            for $type.HOW.attributes($type, :local) {
                nqp::push(@attr, $_.name);
            }
            @attr.sort();
            for @attr -> $name {
                print("\n", $subindent, $type.HOW.name($type), "::", $name, " => ");
                $dumper.'dump'($label, nqp::getattr(self, $type, $name));
            }
        }
        print("\n", $indent, '}');
    }
}
